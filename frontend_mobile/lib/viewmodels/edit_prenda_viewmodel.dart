import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class EditPrendaViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  List<String> tiposPrenda = [];
  bool loadingTipos = false;

  Future<bool> actualizarPrenda({
    required int id,
    required String nombre,
    required String descripcion,
    required double precio,
    required String talla,
    required String color,
    required bool solicitable,
    required List<String> categorias,
    required String estacion,
    required String tipo,
    required String emocion,
  }) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/prendas/api/$id/editar');
    final body = {
      "nombre": nombre,
      "descripcion": descripcion,
      "precio": precio,
      "talla": talla,
      "color": color,
      "solicitable": solicitable,
      "categorias": categorias,
      "estacion": estacion,
      "tipo": tipo,
      "emocion": emocion,
    };

    try {
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        successMessage = "Prenda actualizada con éxito";
        errorMessage = null;
        return true;
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data['error'] ?? 'Error al actualizar';
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

  Future<void> cargarTipos() async {
    loadingTipos = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/prendas/api/tipos');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        tiposPrenda = List<String>.from(data);
      } else {
        print("Error cargando tipos de prenda: ${response.body}");
      }
    } catch (e) {
      print("Error de red al cargar tipos: $e");
    }

    loadingTipos = false;
    notifyListeners();
  }

  Future<bool> eliminarPrenda(int id) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/prendas/api/$id/eliminar');

    try {
      final res = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        successMessage = "Prenda eliminada correctamente";
        errorMessage = null;
        return true;
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data['error'] ?? 'Error al eliminar';
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
}
