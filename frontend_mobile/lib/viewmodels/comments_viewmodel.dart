import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../services/socket_service.dart';

class CommentViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> comentarios = [];
  bool isLoading = false;
  int? idUsuarioActual;

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

  Future<void> fetchComentarios(int postId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final url = Uri.parse('$baseURL/posts/api/$postId/comments');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      comentarios = data.cast<Map<String, dynamic>>();
    } else {
      comentarios = [];
      print("Error: ${response.body}");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> enviarComentario(int postId, String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || texto.trim().isEmpty) return;

    final url = Uri.parse('$baseURL/posts/api/$postId/comments');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contenido': texto}),
    );

    if (response.statusCode == 201) {
      await fetchComentarios(postId); // recargar tras comentar
    } else {
      print("Error al enviar comentario: ${response.body}");
    }
  }

  void initSocketComments(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    idUsuarioActual = _getUserIdFromToken(token);

    if (idUsuarioActual == null) {
      print("⚠️ ID de usuario no disponible para socket");
      return;
    }

    final socketService = SocketService();
    socketService.init(
      userId: idUsuarioActual!,
    ); // solo si aún no se había hecho

    socketService.listenToComments(postId, (data) {
      comentarios.insert(0, Map<String, dynamic>.from(data));
      notifyListeners();
    });
  }
}
