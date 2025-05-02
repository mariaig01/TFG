import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/group.dart';
import '../env.dart';

class GroupViewModel extends ChangeNotifier {
  List<GroupModel> groups = [];
  bool isLoading = false;

  Future<void> loadGroupsForUser() async {
    isLoading = true;
    notifyListeners();

    groups.clear();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/groups/user-groups');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        groups = data.map((e) => GroupModel.fromJson(e)).toList();
      } else {
        print('Error al cargar grupos: ${response.body}');
      }
    } catch (e) {
      print('Error cargando grupos: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> crearGrupo(String nombre, File? imagenFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final uri = Uri.parse('$baseURL/groups/create');

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['nombre'] = nombre;

    if (imagenFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenFile.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print("Grupo creado con éxito");
        await loadGroupsForUser();
      } else {
        print("Error al crear grupo: ${response.body}");
      }
    } catch (e) {
      print("Error de red al crear grupo: $e");
    }
  }

  Future<bool> enviarMensajeGrupo({
    required int grupoId,
    required String mensaje,
    int? idPublicacion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/mensajes/grupo/$grupoId');

    final Map<String, dynamic> body = {'mensaje': mensaje};
    if (idPublicacion != null) {
      body['id_publicacion'] = idPublicacion;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 201;
  }

  Future<bool> unirseAGrupo(int grupoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/groups/$grupoId/join');

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("Te has unido al grupo $grupoId");
        return true;
      } else {
        print("Error al unirse al grupo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error al enviar petición de unirse al grupo: $e");
      return false;
    }
  }

  Future<bool> abandonarGrupo(int grupoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/groups/$grupoId/leave');

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("Abandonaste el grupo $grupoId");
        return true;
      } else {
        print("Error al abandonar el grupo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción al abandonar grupo: $e");
      return false;
    }
  }

  Future<void> eliminarGrupo(int grupoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/groups/$grupoId/delete');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception("Error al eliminar grupo: ${response.body}");
    }
  }
}
