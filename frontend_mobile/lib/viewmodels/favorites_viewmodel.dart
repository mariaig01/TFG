import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../services/http_auth_service.dart';

class FavoritesViewModel with ChangeNotifier {
  Future<bool> toggleGuardarPublicacion(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return false;

    final url = Uri.parse('$baseURL/posts/$postId/guardar-toggle');

    final res = await httpPostConAuth(url, {});
    return res.statusCode == 200 || res.statusCode == 201;
  }
}
