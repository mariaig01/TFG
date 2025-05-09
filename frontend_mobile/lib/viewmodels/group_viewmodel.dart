import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/group.dart';
import '../env.dart';
import '../services/http_auth_service.dart';

class GroupViewModel extends ChangeNotifier {
  List<GroupModel> groups = [];
  bool isLoading = false;

  Future<void> loadGroupsForUser() async {
    isLoading = true;
    notifyListeners();

    groups.clear();

    final url = Uri.parse('$baseURL/groups/user-groups');

    try {
      final response = await httpGetConAuth(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Grupos cargados: $data');
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
    final uri = Uri.parse('$baseURL/groups/create');
    final campos = {'nombre': nombre};

    if (imagenFile != null) {
      final response = await httpMultipartPostConAuth(
        url: uri,
        filePath: imagenFile.path,
        field: 'imagen',
        fields: campos,
      );

      if (response != null && response.statusCode == 201) {
        print("Grupo creado con éxito");
        await loadGroupsForUser();
      } else {
        print("Error al crear grupo: ${response?.body}");
      }
    } else {
      print("Imagen requerida para crear grupo");
    }
  }

  Future<bool> enviarMensajeGrupo({
    required int grupoId,
    required String mensaje,
    int? idPublicacion,
  }) async {
    final url = Uri.parse('$baseURL/mensajes/grupo/$grupoId');

    final Map<String, dynamic> body = {
      'mensaje': mensaje,
      if (idPublicacion != null) 'id_publicacion': idPublicacion,
    };

    final response = await httpPostConAuth(url, body);
    return response.statusCode == 201;
  }

  Future<bool> unirseAGrupo(int grupoId) async {
    final url = Uri.parse('$baseURL/groups/$grupoId/join');

    try {
      final response = await httpPostConAuth(url, {});

      if (response.statusCode == 200) {
        print("Te has unido al grupo $grupoId");
        return true;
      } else {
        print("Error al unirse al grupo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción al unirse al grupo: $e");
      return false;
    }
  }

  Future<bool> abandonarGrupo(int grupoId) async {
    final url = Uri.parse('$baseURL/groups/$grupoId/leave');

    try {
      final response = await httpPostConAuth(url, {});

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
    final url = Uri.parse('$baseURL/groups/$grupoId/delete');
    final response = await httpDeleteConAuth(url);

    if (response.statusCode != 200) {
      throw Exception("Error al eliminar grupo: ${response.body}");
    }
  }
}
