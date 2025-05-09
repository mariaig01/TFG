import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../services/http_auth_service.dart';

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
    if (nuevaImagen == null) return true; // Nada que subir

    final url = Uri.parse('$baseURL/usuarios/subir-imagen-perfil');

    try {
      final response = await httpMultipartPostConAuth(
        url: url,
        filePath: nuevaImagen!.path,
        field: 'imagen',
      );

      if (response != null && response.statusCode == 200) {
        nuevaImagen = null;
        return true;
      } else {
        print('❌ Error al subir imagen: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('⚠️ Excepción al subir imagen: $e');
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
      final response = await httpPutConAuth(url, {
        'nombre': nombre,
        'apellido': apellido,
        'bio': bio,
        'username': username,
      });

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
