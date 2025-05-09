import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../env.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/prenda.dart';
import '../models/post.dart';
import '../services/http_auth_service.dart';

class ProfileViewModel with ChangeNotifier {
  UserModel? _user;

  List<UserModel> listaSeguidores = [];
  List<UserModel> listaSeguidos = [];
  List<UserModel> listaAmigos = [];
  List<PostModel> publicacionesPropias = [];
  List<PostModel> publicacionesGuardadas = [];

  List<Prenda> prendasGuardadas = [];

  UserModel? get user => _user;

  int get seguidores => listaSeguidores.length;
  int get seguidos => listaSeguidos.length;
  int get amigos => listaAmigos.length;

  Future<void> cargarPerfil(int userId) async {
    final urlUsuario = Uri.parse('$baseURL/usuarios/$userId');
    final userRes = await httpGetConAuth(urlUsuario);

    final urlSeguidores = Uri.parse('$baseURL/usuarios/$userId/seguidores');
    final seguidoresRes = await httpGetConAuth(urlSeguidores);

    final urlSeguidos = Uri.parse('$baseURL/usuarios/$userId/seguidos');
    final seguidosRes = await httpGetConAuth(urlSeguidos);

    final urlAmigos = Uri.parse('$baseURL/usuarios/$userId/amigos');
    final amigosRes = await httpGetConAuth(urlAmigos);

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
      final data = jsonDecode(res.body) as List;
      publicacionesPropias = data.map((e) => PostModel.fromJson(e)).toList();

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
      final data = jsonDecode(res.body) as List;
      publicacionesGuardadas = data.map((e) => PostModel.fromJson(e)).toList();

      notifyListeners();
    } else {
      print("Error al obtener publicaciones guardadas: ${res.body}");
    }
  }

  Future<void> cargarPrendasGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final res = await http.get(
      Uri.parse('$baseURL/usuarios/prendas-guardadas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      prendasGuardadas = data.map((e) => Prenda.fromJson(e)).toList();

      notifyListeners();
    }
  }

  //para mostrar o no el boton de solicitar prenda
  Future<UserModel?> obtenerRelacionConUsuario(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final res = await http.get(
      Uri.parse('$baseURL/usuarios/$userId/relacion'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return UserModel(
        id: userId,
        username: '', // puedes dejarlo vacío si no viene
        tipo: data['relacion'],
        estado: data['estado'],
        estadoSeguidor: data['estado_seguidor'],
      );
    } else {
      return null;
    }
  }
}
