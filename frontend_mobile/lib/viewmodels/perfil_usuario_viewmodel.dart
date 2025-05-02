import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../env.dart';

class PerfilUsuarioViewModel extends ChangeNotifier {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> publicaciones = [];
  List<Map<String, dynamic>> prendas = [];
  bool isLoading = false;

  Future<void> cargarTodo(int userId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final resUser = await http.get(
        Uri.parse('$baseURL/usuarios/$userId'),
        headers: headers,
      );

      if (resUser.statusCode != 200) {
        user = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      user = jsonDecode(resUser.body);

      final pubRes = await http.get(
        Uri.parse('$baseURL/usuarios/publicaciones/usuario/$userId'),
        headers: headers,
      );
      if (pubRes.statusCode == 200) {
        publicaciones = List<Map<String, dynamic>>.from(
          jsonDecode(pubRes.body),
        );
      }

      final prendasRes = await http.get(
        Uri.parse('$baseURL/prendas/usuario/$userId'),
        headers: headers,
      );
      if (prendasRes.statusCode == 200) {
        prendas = List<Map<String, dynamic>>.from(jsonDecode(prendasRes.body));
      }

      final relRes = await http.get(
        Uri.parse('$baseURL/usuarios/$userId/relacion'),
        headers: headers,
      );
      if (relRes.statusCode == 200 && user != null) {
        final relData = jsonDecode(relRes.body);
        user!['relacion'] = relData['relacion'];
        user!['estado'] = relData['estado'];
        if (relData.containsKey('estado_seguidor')) {
          user!['estado_seguidor'] = relData['estado_seguidor'];
        } else {
          user!.remove('estado_seguidor');
        }
      }
    } catch (e) {
      print('❌ Error al cargar perfil de usuario: $e');
      user = null;
    }

    isLoading = false;
    notifyListeners();
  }
}
