import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Intenta registrar al usuario y devuelve true si tiene éxito
  Future<bool> register({
    required String username,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.registerUser(
      username: username,
      nombre: nombre,
      apellido: apellido,
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['ok']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }
}
