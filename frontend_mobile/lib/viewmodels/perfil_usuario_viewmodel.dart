import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/prenda.dart';
import '../services/http_auth_service.dart';

class PerfilUsuarioViewModel extends ChangeNotifier {
  UserModel? user;
  List<PostModel> publicaciones = [];
  List<Prenda> prendas = [];
  bool isLoading = false;

  Future<void> cargarTodo(int userId) async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final url = Uri.parse('$baseURL/usuarios/$userId');
      final resUser = await httpGetConAuth(url);

      if (resUser.statusCode != 200) {
        user = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(resUser.body);
      print('DEBUG USER JSON: $decoded');

      user = UserModel.fromJson(jsonDecode(resUser.body));

      final urlPub = Uri.parse(
        '$baseURL/usuarios/publicaciones/usuario/$userId',
      );
      final pubRes = await httpGetConAuth(urlPub);
      if (pubRes.statusCode == 200) {
        print('DEBUG pubRes.body = ${pubRes.body}');

        final dataPub = jsonDecode(pubRes.body);
        publicaciones = List<PostModel>.from(
          dataPub.map((p) => PostModel.fromJson(p)),
        );
      } else {
        print('Error al cargar publicaciones: ${pubRes.body}');
      }

      final urlPrenda = Uri.parse('$baseURL/prendas/usuario/$userId');
      final prendaRes = await httpGetConAuth(urlPrenda);
      if (prendaRes.statusCode == 200) {
        print(' DEBUG prendaRes.body = ${prendaRes.body}');

        final dataPrenda = jsonDecode(prendaRes.body);
        prendas = List<Prenda>.from(dataPrenda.map((p) => Prenda.fromJson(p)));
      }

      final relRes = await http.get(
        Uri.parse('$baseURL/usuarios/$userId/relacion'),
        headers: headers,
      );
      if (relRes.statusCode == 200 && user != null) {
        final relData = jsonDecode(relRes.body);
        print('DEBUG REL DATA: ${relRes.body}');
        print('DECODED: ${jsonDecode(relRes.body)}');

        user = user!.copyWith(
          tipo: relData['relacion'],
          estado: relData['estado'],
          estadoSeguidor:
              relData.containsKey('estado_seguidor')
                  ? relData['estado_seguidor']
                  : null,
        );
      }

      if (pubRes.statusCode != 200) {
        print('Error al cargar publicaciones: ${pubRes.body}');
      }
      if (prendaRes.statusCode != 200) {
        print('Error al cargar prendas: ${prendaRes.body}');
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      user = null;
    }

    isLoading = false;
    notifyListeners();
  }
}
