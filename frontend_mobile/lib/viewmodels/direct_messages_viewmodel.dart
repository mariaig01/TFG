// direct_messages_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env.dart';
import '../models/direct_message_model.dart';
import '../services/socket_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/mensajes/directo');

    final body = {'id_receptor': receptorId, 'mensaje': mensaje};

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    idUsuarioActual = _getUserIdFromToken(token);

    final url = Uri.parse('$baseURL/mensajes/directo/$otroUsuarioId');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        mensajes = List<DirectMessage>.from(
          data.map((e) => DirectMessage.fromJson(e)),
        );
      }
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  int? _getUserIdFromToken(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final data = jsonDecode(payload);
    return int.tryParse(data['sub'].toString());
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
      onGroupMessage: (_) {}, // No se usa aquí
    );
  }
}
