// lib/viewmodels/miarmario_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env.dart';

class MiArmarioViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> prendas = [];
  bool isLoading = false;

  String? colorSeleccionado;
  String? tipoSeleccionado;
  String? estacionSeleccionada;
  String? categoriaSeleccionada;

  List<String> colores = [];
  List<String> tipos = [];
  List<String> estaciones = [];
  List<String> categorias = [];

  List<Map<String, dynamic>> get prendasFiltradas {
    return prendas.where((p) {
      final colorOk =
          colorSeleccionado == null || p['color'] == colorSeleccionado;
      final tipoOk = tipoSeleccionado == null || p['tipo'] == tipoSeleccionado;
      final estacionOk =
          estacionSeleccionada == null || p['estacion'] == estacionSeleccionada;
      final categoriaOk =
          categoriaSeleccionada == null ||
          (p['categorias'] as List?)?.contains(categoriaSeleccionada) == true;

      return colorOk && tipoOk && estacionOk && categoriaOk;
    }).toList();
  }

  Future<void> cargarPrendas() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final res = await http.get(
      Uri.parse('$baseURL/prendas/api/mis-prendas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      prendas = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      colores = prendas.map((p) => p['color'].toString()).toSet().toList();
      tipos = prendas.map((p) => p['tipo']?.toString() ?? '').toSet().toList();
      estaciones =
          prendas.map((p) => p['estacion']?.toString() ?? '').toSet().toList();

      // Unir todas las listas de categorías
      final todasLasCategorias =
          prendas
              .map((p) => p['categorias'] as List<dynamic>? ?? [])
              .expand((e) => e)
              .toSet()
              .map((e) => e.toString())
              .toList();

      categorias = todasLasCategorias;
    } else {
      prendas = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void seleccionarColor(String? color) {
    colorSeleccionado = color;
    notifyListeners();
  }

  void seleccionarTipo(String? tipo) {
    tipoSeleccionado = tipo;
    notifyListeners();
  }

  void seleccionarEstacion(String? estacion) {
    estacionSeleccionada = estacion;
    notifyListeners();
  }

  void seleccionarCategoria(String? categoria) {
    categoriaSeleccionada = categoria;
    notifyListeners();
  }
}
