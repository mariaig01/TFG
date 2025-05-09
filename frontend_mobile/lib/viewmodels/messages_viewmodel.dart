// messages_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env.dart';
import '../models/user.dart';

class MessagesViewModel extends ChangeNotifier {
  List<UserModel> usuarios = [];
  bool isLoading = false;

  Future<void> fetchConversaciones() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('$baseURL/mensajes/usuarios-conversacion');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        usuarios =
            (data as List).map((json) => UserModel.fromJson(json)).toList();
      } else {
        print("Error al obtener usuarios: ${response.body}");
      }
    } catch (e) {
      print("Excepción: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> enviarMensajeDirecto({
    required int receptorId,
    String mensaje = '',
    int? publicacionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = Uri.parse('$baseURL/mensajes/directo');

    final body = {'id_receptor': receptorId, 'mensaje': mensaje};

    if (publicacionId != null) {
      body['id_publicacion'] = publicacionId;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      print('Error al enviar mensaje directo: ${response.body}');
    } else {
      print('Mensaje enviado correctamente');
    }
  }
}
