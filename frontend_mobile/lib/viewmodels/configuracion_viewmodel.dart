import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class SettingsViewModel with ChangeNotifier {
  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  File? nuevaImagen;

  Future<void> seleccionarImagenDesdeGaleria() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      nuevaImagen = File(pickedFile.path);
      notifyListeners(); // Actualiza la pantalla para mostrar la imagen
    }
  }

  Future<bool> subirNuevaFotoPerfil() async {
    if (nuevaImagen == null)
      return true; // Si no hay nueva imagen, no hacemos nada

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return false;

    final url = Uri.parse('$baseURL/usuarios/subir-imagen-perfil');

    try {
      final request =
          http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(
              await http.MultipartFile.fromPath('imagen', nuevaImagen!.path),
            );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        nuevaImagen = null; // ✅ Limpiar la imagen temporal tras subir
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error subiendo imagen: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> actualizarDatosPerfil({
    required String nombre,
    required String apellido,
    required String bio,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return {'ok': false, 'error': 'Token no disponible'};

    final url = Uri.parse('$baseURL/usuarios/editar');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'bio': bio,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        return {'ok': true};
      } else {
        final Map<String, dynamic> respuesta = jsonDecode(response.body);
        return {
          'ok': false,
          'error': respuesta['error'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      print('Error actualizando datos: $e');
      return {'ok': false, 'error': 'Error de conexión'};
    }
  }
}
