import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class SearchViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> grupos = [];
  bool isLoading = false;

  Future<void> buscar(String query) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/api/buscar?q=$query');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        usuarios = List<Map<String, dynamic>>.from(data['usuarios']);
        grupos = List<Map<String, dynamic>>.from(data['grupos']);
      } else {
        usuarios = [];
        grupos = [];
      }
    } catch (e) {
      usuarios = [];
      grupos = [];
      print('❌ Error en búsqueda: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void limpiarResultados() {
    usuarios.clear();
    grupos.clear();
    notifyListeners();
  }

  Future<bool> enviarSolicitud(int idReceptor, {required String tipo}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/usuarios/solicitud');

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id_receptor': idReceptor, 'tipo': tipo}),
      );

      return res.statusCode == 201;
    } catch (e) {
      print("❌ Error al enviar solicitud: $e");
      return false;
    }
  }

  Future<bool> eliminarRelacion(int idReceptor, {required String tipo}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/usuarios/relacion'); // corregido

    try {
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id_receptor': idReceptor, 'tipo': tipo}),
      );

      if (res.statusCode == 200) {
        print("✅ Relación eliminada con éxito");
        return true;
      } else {
        print("⚠️ Fallo al eliminar relación: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error al eliminar relación: $e");
      return false;
    }
  }
}
