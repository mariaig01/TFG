import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> solicitudes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchSolicitudes() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/usuarios/solicitudes-recibidas');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        solicitudes =
            List<Map<String, dynamic>>.from(jsonDecode(res.body)).map((s) {
              s["tipo"] =
                  s["tipo"] ??
                  "prenda"; // Asegura que se etiqueten como 'prenda' si no lo están
              return s;
            }).toList();
      } else {
        solicitudes = [];
        print("⚠️ Error al obtener solicitudes: ${res.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
      solicitudes = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> responderSolicitud(
    dynamic id,
    String tipo, {
    required bool aceptar,
  }) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      String endpoint;
      Map<String, dynamic> body;

      if (tipo == 'amigo' || tipo == 'seguidor') {
        endpoint = '$baseURL/usuarios/${aceptar ? "aceptar" : "rechazar"}';
        body = {"id_emisor": int.parse(id.toString()), "tipo": tipo};
      } else if (tipo == 'prenda') {
        endpoint =
            '$baseURL/prendas/solicitudes/$id/${aceptar ? "aceptar" : "rechazar"}';
        body = {}; // No necesita body para prenda, solo POST simple
      } else {
        throw Exception('Tipo de solicitud no válido');
      }

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        solicitudes.removeWhere((s) => s["id"].toString() == id.toString());
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data['error'] ?? 'Error al responder solicitud';
      }
    } catch (e) {
      errorMessage = "Error de red: $e";
    }

    isLoading = false;
    notifyListeners();
  }
}
