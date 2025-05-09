import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? errorMessage;
  bool isLoading = false;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      // Llamada al servicio de autenticación
      final tokens = await _authService.login(email, password);

      if (tokens != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', tokens['access_token']!);
        await prefs.setString('refresh_token', tokens['refresh_token']!);
        errorMessage = null;
        return true;
      } else {
        errorMessage = "Credenciales incorrectas";
        return false;
      }
    } catch (e) {
      // Manejo de errores
      errorMessage = "Error: El servidor no responde";
      return false;
    } finally {
      // Asegura que el estado de carga se desactive
      isLoading = false;
      notifyListeners();
    }
  }
}
