import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../models/post.dart';
import '../services/http_auth_service.dart';

class FeedViewModel extends ChangeNotifier {
  List<PostModel> publicaciones = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> cargarFeed() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        errorMessage = 'Token no encontrado';
        isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('$baseURL/posts/feed');

      final response = await httpGetConAuth(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        publicaciones =
            (data['posts'] as List).map((p) => PostModel.fromJson(p)).toList();
      } else {
        errorMessage = 'Error: ${response.body}';
      }
    } catch (e) {
      errorMessage = 'Error de red: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void actualizarEstadoGuardado(int postId, bool nuevoEstado) {
    final index = publicaciones.indexWhere((p) => p.id == postId);
    if (index != -1) {
      publicaciones[index] = publicaciones[index].copyWith(
        guardado: nuevoEstado,
      );
      notifyListeners();
    }
  }

  void actualizarPost(PostModel actualizado) {
    final index = publicaciones.indexWhere((p) => p.id == actualizado.id);
    if (index != -1) {
      publicaciones[index] = actualizado;
      notifyListeners();
    }
  }
}
