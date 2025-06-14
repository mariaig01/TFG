import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../env.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> resetPassword(String token, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final uri = Uri.parse('$baseURL/auth/reset-password');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'password': password}),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return true;
      } else {
        errorMessage = body['error'] ?? 'Error desconocido';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error de red o del servidor';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
