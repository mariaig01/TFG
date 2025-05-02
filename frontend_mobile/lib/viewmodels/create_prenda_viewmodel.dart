import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class CreatePrendaViewModel with ChangeNotifier {
  String? errorMessage;
  List<String> tiposPrenda = [];
  bool cargandoTipos = false;
  String? tipoSeleccionado;
  String? emocionSeleccionada = 'neutro';

  Future<void> createPrenda({
    required String nombre,
    required String descripcion,
    required double precio,
    required String talla,
    required String color,
    required bool solicitable,
    required File? imagen,
    required bool eliminarFondo,
    required List<String> categorias,
    required String estacion,
  }) async {
    errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        errorMessage = 'No hay token de autenticación';
        notifyListeners();
        return;
      }

      final uri = Uri.parse("$baseURL/prendas/api/create");
      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nombre'] = nombre;
      request.fields['descripcion'] = descripcion;
      request.fields['precio'] = precio.toString();
      request.fields['talla'] = talla;
      request.fields['color'] = color;
      request.fields['solicitable'] = solicitable.toString();
      request.fields['eliminar_fondo'] = eliminarFondo.toString();
      request.fields['categorias'] = categorias.join(',');
      request.fields['estacion'] = estacion;
      request.fields['tipo'] = tipoSeleccionado ?? '';
      request.fields['emocion'] = emocionSeleccionada ?? 'neutro';

      if (imagen != null) {
        final imagenMultipart = await http.MultipartFile.fromPath(
          'imagen',
          imagen.path,
        );
        request.files.add(imagenMultipart);
      } else {
        errorMessage = 'La imagen es obligatoria';
        notifyListeners();
        return;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        errorMessage = null;
      } else {
        errorMessage =
            jsonDecode(response.body)['error'] ?? 'Error al subir prenda';
      }
    } catch (e) {
      errorMessage = 'Error inesperado: $e';
    }

    notifyListeners();
  }

  Future<void> cargarTiposDesdeBackend() async {
    cargandoTipos = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/prendas/api/tipos');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        tiposPrenda = List<String>.from(jsonDecode(res.body));
      } else {
        print('❌ Error al obtener tipos: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción al obtener tipos: $e');
    }

    cargandoTipos = false;
    notifyListeners();
  }
}
