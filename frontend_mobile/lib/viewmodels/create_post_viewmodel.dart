import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class CreatePostViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> createPost({
    required String contenido,
    required String visibilidad,
    File? imagen,
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final uri = Uri.parse('$baseURL/posts/api/create-mobile');

    try {
      print("🛰 Enviando publicación...");
      print("Contenido: $contenido");
      print("Visibilidad: $visibilidad");
      print("Imagen: ${imagen?.path}");
      print("🔐 Token: $token");

      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $token'
            ..fields['contenido'] = contenido
            ..fields['visibilidad'] = visibilidad;

      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
      } else {
        request.fields['imagen_url'] = '';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📬 Código de respuesta: ${response.statusCode}");
      print("📬 Body: ${response.body}");

      if (response.statusCode == 201) {
        successMessage = 'Publicación creada con éxito';
        errorMessage = null;
      } else {
        errorMessage = 'Error: ${response.body}';
        successMessage = null;
      }
    } catch (e) {
      print("❌ Error: $e");
      errorMessage = 'Error de red o del servidor: $e';
      successMessage = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
