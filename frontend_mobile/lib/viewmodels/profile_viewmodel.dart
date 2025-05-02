import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../env.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel with ChangeNotifier {
  UserModel? _user;

  List<UserModel> listaSeguidores = [];
  List<UserModel> listaSeguidos = [];
  List<UserModel> listaAmigos = [];
  List<Map<String, dynamic>> publicacionesPropias = [];
  List<Map<String, dynamic>> publicacionesGuardadas = [];

  UserModel? get user => _user;

  int get seguidores => listaSeguidores.length;
  int get seguidos => listaSeguidos.length;
  int get amigos => listaAmigos.length;

  Future<void> cargarPerfil(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final base = '$baseURL/usuarios/$userId';

    final userRes = await http.get(Uri.parse(base), headers: headers);
    final seguidoresRes = await http.get(
      Uri.parse('$base/seguidores'),
      headers: headers,
    );
    final seguidosRes = await http.get(
      Uri.parse('$base/seguidos'),
      headers: headers,
    );
    final amigosRes = await http.get(
      Uri.parse('$base/amigos'),
      headers: headers,
    );

    if (userRes.statusCode == 200) {
      _user = UserModel.fromJson(jsonDecode(userRes.body));

      listaSeguidores =
          (jsonDecode(seguidoresRes.body) as List)
              .map((json) => UserModel.fromJson(json))
              .toList();

      listaSeguidos =
          (jsonDecode(seguidosRes.body) as List)
              .map((json) => UserModel.fromJson(json))
              .toList();

      listaAmigos =
          (jsonDecode(amigosRes.body) as List)
              .map((json) => UserModel.fromJson(json))
              .toList();

      notifyListeners();
    }
  }

  Future<bool> subirImagenPerfil() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return false;

    final File imagen = File(picked.path);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return false;

    final uri = Uri.parse('$baseURL/usuarios/subir-imagen-perfil');

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath('imagen', imagen.path));

    final responseStream = await request.send();
    final response = await http.Response.fromStream(responseStream);

    if (response.statusCode == 200) {
      // 🔁 Extraer userId del JWT
      final parts = token.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      final userId = int.tryParse(decoded['sub'].toString());

      if (userId != null) {
        await cargarPerfil(userId);
      }

      return true;
    } else {
      print(' Error al subir imagen de perfil: ${response.body}');
      return false;
    }
  }

  Future<void> cargarMisPublicaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    final url = Uri.parse('$baseURL/usuarios/mis-publicaciones');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      publicacionesPropias = List<Map<String, dynamic>>.from(
        jsonDecode(res.body),
      );
      notifyListeners();
    } else {
      print("Error al obtener mis publicaciones: ${res.body}");
    }
  }

  Future<void> cargarPublicacionesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('$baseURL/usuarios/publicaciones-guardadas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      publicacionesGuardadas = List<Map<String, dynamic>>.from(
        jsonDecode(res.body),
      );
      notifyListeners();
    } else {
      print("Error al obtener publicaciones guardadas: ${res.body}");
    }
  }
}
