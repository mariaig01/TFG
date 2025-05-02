import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../env.dart';

class FavoritesViewModel with ChangeNotifier {
  Future<bool> toggleGuardarPublicacion(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return false;

    final res = await http.post(
      Uri.parse('$baseURL/posts/api/$postId/guardar-toggle'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
