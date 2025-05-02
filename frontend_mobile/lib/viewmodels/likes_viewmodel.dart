import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../env.dart';

class LikeViewModel extends ChangeNotifier {
  Future<void> toggleLike(PostModel post, Function(PostModel) onUpdate) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      debugPrint('❌ Token no disponible');
      return;
    }

    final url = Uri.parse('$baseURL/posts/api/${post.id}/like');

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final status = response.statusCode;
      final body = json.decode(response.body);

      if (status == 200 || status == 201) {
        // ✅ Usamos los valores reales que devuelve el backend
        final bool nuevoEstadoLike = body['ha_dado_like'];
        final int nuevoLikesCount = body['likes_count'];

        final updatedPost = post.copyWith(
          haDadoLike: nuevoEstadoLike,
          likesCount: nuevoLikesCount,
        );

        onUpdate(updatedPost);
        notifyListeners();
      } else {
        debugPrint('⚠️ Error al dar like: $status → ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error de red al dar like: $e');
    }
  }
}
