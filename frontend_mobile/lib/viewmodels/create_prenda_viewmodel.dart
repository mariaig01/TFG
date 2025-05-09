import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../env.dart';
import '../models/prenda.dart';
import '../services/http_auth_service.dart';

class CreatePrendaViewModel with ChangeNotifier {
  String? errorMessage;
  List<String> tiposPrenda = [];
  bool cargandoTipos = false;
  String? tipoSeleccionado;
  String? emocionSeleccionada = 'neutro';

  Future<Prenda?> createPrenda({
    required Prenda prenda,
    required File imagen,
    required bool eliminarFondo,
  }) async {
    errorMessage = null;

    try {
      final uri = Uri.parse("$baseURL/prendas/create");

      final fields = {
        'nombre': prenda.nombre,
        'descripcion': prenda.descripcion ?? '',
        'precio': prenda.precio.toString(),
        'talla': prenda.talla,
        'color': prenda.color,
        'solicitable': prenda.solicitable.toString(),
        'eliminar_fondo': eliminarFondo.toString(),
        'categorias': prenda.categorias.join(','),
        'estacion': prenda.estacion ?? 'Cualquiera',
        'tipo': prenda.tipo,
        'emocion': prenda.emocion ?? 'neutro',
      };

      final response = await httpMultipartPostConAuth(
        url: uri,
        filePath: imagen.path,
        field: 'imagen',
        fields: fields,
      );

      if (response != null && response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Prenda.fromJson(data);
      } else {
        final respuesta = response != null ? jsonDecode(response.body) : null;
        errorMessage = respuesta?['error'] ?? 'Error al subir prenda';
      }
    } catch (e) {
      errorMessage = 'Error inesperado: $e';
    }

    notifyListeners();
    return null;
  }

  Future<void> cargarTiposDesdeBackend() async {
    cargandoTipos = true;
    notifyListeners();

    final url = Uri.parse('$baseURL/prendas/tipos');

    try {
      final res = await httpGetConAuth(url);

      if (res.statusCode == 200) {
        tiposPrenda = List<String>.from(jsonDecode(res.body));
      } else {
        print('Error al obtener tipos: ${res.statusCode}');
      }
    } catch (e) {
      print('Excepción al obtener tipos: $e');
    }

    cargandoTipos = false;
    notifyListeners();
  }
}
