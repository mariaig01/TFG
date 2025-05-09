import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../services/socket_service.dart';
import '../services/http_auth_service.dart';
import '../services/auth_service.dart';
import '../models/comment.dart';

class CommentViewModel extends ChangeNotifier {
  List<Comentario> _comentarios = [];
  List<Comentario> get comentarios => _comentarios;
  bool isLoading = false;
  int? idUsuarioActual;
  bool _socketInitialized = false;

  Future<void> fetchComentarios(int postId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final url = Uri.parse('$baseURL/posts/$postId/comments');
    // final response = await http.get(
    //   url,
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    final response = await httpGetConAuth(url);

    if (response.statusCode == 200) {
      final List responseData = jsonDecode(response.body);
      _comentarios =
          responseData
              .map<Comentario>((data) => Comentario.fromJson(data))
              .toList();
    } else {
      _comentarios = [];
      print("Error: ${response.body}");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> enviarComentario(int postId, String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || texto.trim().isEmpty) return;

    final url = Uri.parse('$baseURL/posts/$postId/comments');
    // final response = await http.post(
    //   url,
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({'contenido': texto}),
    // );
    final response = await httpPostConAuth(url, {'contenido': texto});

    if (response.statusCode == 201) {
      await fetchComentarios(postId); // recargar tras comentar
    } else {
      print("Error al enviar comentario: ${response.body}");
    }
  }

  void initSocketComments(int postId) async {
    if (_socketInitialized) return;
    _socketInitialized = true;

    idUsuarioActual = await AuthService.getUserIdFromToken();
    if (idUsuarioActual == null) {
      print("⚠️ ID de usuario no disponible para socket");
      return;
    }

    final socketService = SocketService();
    socketService.init(userId: idUsuarioActual!);

    socketService.listenToComments(postId, (data) {
      final nuevo = Comentario.fromJson(Map<String, dynamic>.from(data));
      if (!_comentarios.any((c) => c.id == nuevo.id)) {
        _comentarios.insert(0, nuevo);
        notifyListeners();
      }
    });
  }
}
