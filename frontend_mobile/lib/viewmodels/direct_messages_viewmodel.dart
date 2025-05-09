// direct_messages_viewmodel.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../env.dart';
import '../models/direct_message_model.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../services/http_auth_service.dart';

class DirectMessagesViewModel extends ChangeNotifier {
  List<DirectMessage> mensajes = [];
  bool isLoading = false;
  int? idUsuarioActual;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> enviarMensaje({
    required int receptorId,
    required String mensaje,
  }) async {
    final url = Uri.parse('$baseURL/mensajes/directo');

    final body = {'id_receptor': receptorId, 'mensaje': mensaje};

    final response = await httpPostConAuth(url, body);

    if (response.statusCode == 201) {
      print('Mensaje enviado correctamente');
      final nuevo = DirectMessage.fromJson(jsonDecode(response.body));
      mensajes.add(nuevo);
      notifyListeners();
    } else {
      print('Error al enviar mensaje: ${response.body}');
    }
  }

  Future<void> obtenerMensajes(int otroUsuarioId) async {
    isLoading = true;
    notifyListeners();
    idUsuarioActual = await AuthService.getUserIdFromToken();

    final url = Uri.parse('$baseURL/mensajes/directo/$otroUsuarioId');

    try {
      final res = await httpGetConAuth(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        mensajes = List<DirectMessage>.from(
          data.map((e) => DirectMessage.fromJson(e)),
        );
      }
    } catch (e) {
      print('Error al obtener mensajes: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void initSocket() {
    print('initSocket llamado para usuario $idUsuarioActual o grupo ...');
    if (idUsuarioActual == null) return;

    final socketService = SocketService();
    socketService.init(
      userId: idUsuarioActual!,
      onDirectMessage: (data) {
        final nuevo = DirectMessage.fromJson(data);
        mensajes.add(nuevo);
        notifyListeners();
      },
    );
  }
}
