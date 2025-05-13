import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class GraficosCostosViewModel extends ChangeNotifier {
  double totalGasto = 0.0;
  Map<String, double> gastosPorTipo = {};
  List<Map<String, dynamic>> evolucionDiaria = [];

  bool isLoading = true;
  bool mostrarPieChart = true;

  Future<void> fetchDatos() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      print('❌ No se encontró token');
      isLoading = false;
      notifyListeners();
      return;
    }

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final totalResp = await http.get(
        Uri.parse('$baseURL/api/costos/total'),
        headers: headers,
      );
      final tipoResp = await http.get(
        Uri.parse('$baseURL/api/costos/por-tipo'),
        headers: headers,
      );
      final evolucionResp = await http.get(
        Uri.parse('$baseURL/api/costos/evolucion'),
        headers: headers,
      );

      print('📦 total: ${totalResp.body}');
      print('📦 por tipo: ${tipoResp.body}');
      print('📦 evolucion: ${evolucionResp.body}');

      totalGasto = json.decode(totalResp.body)['total'];

      final tipoMap = Map<String, dynamic>.from(json.decode(tipoResp.body));
      gastosPorTipo = tipoMap.map((k, v) => MapEntry(k, (v as num).toDouble()))
        ..removeWhere((_, v) => v <= 0.0);

      final evolucionJson = List<Map<String, dynamic>>.from(
        json.decode(evolucionResp.body),
      );
      evolucionDiaria =
          evolucionJson.map((e) {
            final dia = e['dia'] ?? e['mes'];
            return {'dia': dia, 'total': (e['total'] as num).toDouble()};
          }).toList();

      print('✅ gastosPorTipo: $gastosPorTipo');
      print('✅ evolucionDiaria: $evolucionDiaria');
    } catch (e) {
      print('❌ Error cargando datos: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void alternarGrafico() {
    mostrarPieChart = !mostrarPieChart;
    notifyListeners();
  }
}
