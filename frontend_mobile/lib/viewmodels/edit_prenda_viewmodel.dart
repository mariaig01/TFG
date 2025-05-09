import 'dart:convert';
import 'package:flutter/material.dart';
import '../env.dart';
import '../services/http_auth_service.dart';

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

    final url = Uri.parse('$baseURL/prendas/$id/editar');
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
      final res = await httpPutConAuth(url, body);

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

    final url = Uri.parse('$baseURL/prendas/tipos');

    try {
      final response = await httpGetConAuth(url);
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
    final url = Uri.parse('$baseURL/prendas/$id/eliminar');

    try {
      final res = await httpDeleteConAuth(url);
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
