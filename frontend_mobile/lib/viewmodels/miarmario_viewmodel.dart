import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env.dart';
import '../models/prenda.dart';

class MiArmarioViewModel extends ChangeNotifier {
  List<Prenda> _prendas = [];
  bool isLoading = false;

  String? colorSeleccionado;
  String? tipoSeleccionado;
  String? estacionSeleccionada;
  String? categoriaSeleccionada;

  List<String> colores = [];
  List<String> tipos = [];
  List<String> estaciones = [];
  List<String> categorias = [];

  List<Prenda> get prendasFiltradas {
    return _prendas.where((p) {
      final colorOk = colorSeleccionado == null || p.color == colorSeleccionado;
      final tipoOk = tipoSeleccionado == null || p.tipo == tipoSeleccionado;
      final estacionOk =
          estacionSeleccionada == null || p.estacion == estacionSeleccionada;
      final categoriaOk =
          categoriaSeleccionada == null ||
          p.categorias.contains(categoriaSeleccionada);
      return colorOk && tipoOk && estacionOk && categoriaOk;
    }).toList();
  }

  Future<void> cargarPrendas() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final res = await http.get(
      Uri.parse('$baseURL/prendas/mis-prendas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      _prendas = data.map((item) => Prenda.fromJson(item)).toList();

      colores = _prendas.map((p) => p.color).toSet().toList();
      tipos = _prendas.map((p) => p.tipo).toSet().toList();
      estaciones =
          _prendas
              .map((p) => p.estacion ?? '')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();

      final todasLasCategorias =
          _prendas.expand((p) => p.categorias).toSet().toList();

      categorias = todasLasCategorias;
    } else {
      _prendas = [];
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
