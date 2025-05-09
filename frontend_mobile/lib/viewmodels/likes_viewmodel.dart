import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../env.dart';
import '../services/http_auth_service.dart';

class LikeViewModel extends ChangeNotifier {
  Future<void> toggleLike(PostModel post, Function(PostModel) onUpdate) async {
    final url = Uri.parse('$baseURL/posts/${post.id}/like');

    try {
      final response = await httpPostConAuth(url, {});

      final status = response.statusCode;
      final body = json.decode(response.body);

      if (status == 200 || status == 201) {
        // Usamos los valores reales que devuelve el backend
        final bool nuevoEstadoLike = body['ha_dado_like'];
        final int nuevoLikesCount = body['likes_count'];

        final updatedPost = post.copyWith(
          haDadoLike: nuevoEstadoLike,
          likesCount: nuevoLikesCount,
        );

        onUpdate(updatedPost);
        notifyListeners();
      } else {
        debugPrint('Error al dar like: $status → ${response.body}');
      }
    } catch (e) {
      debugPrint('Error de red al dar like: $e');
    }
  }
}
