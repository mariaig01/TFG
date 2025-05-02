import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import 'package:intl/intl.dart';

class PrendaDetailViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  bool enPrestamo = false;
  DateTime? fechaFinPrestamo;

  Future<bool> solicitarPrenda(
    int prendaId, {
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final formato = DateFormat("yyyy-MM-ddTHH:mm");
    final inicioStr = formato.format(fechaInicio);
    final finStr = formato.format(fechaFin);

    try {
      final res = await http.post(
        Uri.parse('$baseURL/prendas/$prendaId/solicitar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'fecha_inicio': inicioStr, 'fecha_fin': finStr},
      );

      if (res.statusCode == 201) {
        successMessage = "Solicitud enviada correctamente";
        errorMessage = null;
        return true;
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data['error'] ?? "Error al enviar solicitud";
        return false;
      }
    } catch (e) {
      errorMessage = "Error de red: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verificarEstadoPrestamo(int prendaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final res = await http.get(
        Uri.parse('$baseURL/prendas/$prendaId/prestamo-actual'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        enPrestamo = data['en_prestamo'];
        if (enPrestamo) {
          fechaFinPrestamo = DateTime.parse(data['fecha_fin']);
        } else {
          fechaFinPrestamo = null;
        }
      }
    } catch (e) {
      print(' Error al verificar estado de préstamo: $e');
    }
    notifyListeners();
  }
}
