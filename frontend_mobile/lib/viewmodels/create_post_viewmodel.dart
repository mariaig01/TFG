import 'package:flutter/material.dart';
import 'dart:io';
import '../env.dart';
import '../services/http_auth_service.dart';

class CreatePostViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> createPost({
    required String contenido,
    required String visibilidad,
    required File imagen, // <-- obligatorio
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final uri = Uri.parse('$baseURL/posts/create-mobile');

    try {
      final response = await httpMultipartPostConAuth(
        url: uri,
        filePath: imagen.path,
        field: 'imagen',
        fields: {'contenido': contenido, 'visibilidad': visibilidad},
      );

      if (response != null && response.statusCode == 201) {
        successMessage = 'Publicación creada con éxito';
      } else {
        errorMessage = 'Error: ${response?.body ?? 'sin respuesta'}';
      }
    } catch (e) {
      print("Error: $e");
      errorMessage = 'Error de red o del servidor: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
