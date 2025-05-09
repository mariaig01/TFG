import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../env.dart';

class PostViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> editarPost(
    int postId,
    String contenido,
    String visibilidad,
  ) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/posts/$postId/editar');

    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contenido': contenido, 'visibilidad': visibilidad}),
    );

    isLoading = false;
    notifyListeners();

    if (res.statusCode == 200) {
      successMessage = 'Publicación actualizada con éxito';
      return true;
    } else {
      errorMessage = jsonDecode(res.body)['error'] ?? 'Error al actualizar';
      return false;
    }
  }

  Future<bool> eliminarPost(int postId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/posts/$postId/eliminar');

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    isLoading = false;
    notifyListeners();

    if (res.statusCode == 200) {
      successMessage = 'Publicación eliminada correctamente';
      return true;
    } else {
      errorMessage = jsonDecode(res.body)['error'] ?? 'Error al eliminar';
      return false;
    }
  }
}
