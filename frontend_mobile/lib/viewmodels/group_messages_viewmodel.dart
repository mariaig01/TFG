import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../env.dart';
import '../models/group_messages.dart';
import '../services/socket_service.dart';

class GroupMessagesViewModel extends ChangeNotifier {
  List<GroupMessage> messages = [];
  bool isLoading = false;
  int? idUsuarioActual;
  String? usernameActual;

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

  Future<void> loadMessages(String groupId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    idUsuarioActual = _getUserIdFromToken(token);
    usernameActual = _getUsernameFromToken(token);

    final url = Uri.parse('$baseURL/mensajes/grupo/$groupId');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        messages = List<GroupMessage>.from(
          data.map((msg) => GroupMessage.fromJson(msg)),
        );
      } else {
        print("❌ Error al cargar mensajes: ${res.body}");
      }
    } catch (e) {
      print("❌ Error al obtener mensajes: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  String? _getUsernameFromToken(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final data = jsonDecode(payload);
    return data['username']; // o 'sub' si lo has guardado así
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

  Future<Map<String, dynamic>> loadGroupInfo(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/groups/$groupId/info');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("⚠️ Error al cargar info grupo: ${res.body}");
      }
    } catch (e) {
      print("❌ Error obteniendo info del grupo: $e");
    }

    return {'creador': 'Desconocido', 'num_miembros': 0};
  }

  void initSocketGrupo(int grupoId) {
    if (idUsuarioActual == null) {
      print("❗ No se ha establecido el ID del usuario");
      return;
    }

    print(
      'initSocketGrupo llamado para usuario $idUsuarioActual en grupo $grupoId',
    );

    final socketService = SocketService();

    socketService.init(
      userId: idUsuarioActual!,
      onDirectMessage: (_) {},
      onGroupMessage: (data) {
        if (_disposed) return;
        print(' [SOCKET] Recibido mensaje de grupo: $data');
        final nuevo = GroupMessage.fromJson(data);
        if (!messages.any((m) => m.id == nuevo.id)) {
          messages.add(nuevo);
          notifyListeners();
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      socketService.joinGroup(grupoId);
      print(' Usuario $idUsuarioActual se ha unido a grupo $grupoId');
    });
  }
}
