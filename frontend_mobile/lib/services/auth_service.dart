import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class AuthService {
  final String baseUrl = '$baseURL/auth';

  /// LOGIN
  Future<Map<String, String>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
      };
    } else {
      return null;
    }
  }

  /// REFRESH
  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['access_token'];
      await prefs.setString('jwt_token', newAccessToken);
      return newAccessToken;
    } else {
      return null;
    }
  }

  /// REGISTRO
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'bio': '',
        'rol': 'usuario',
      }),
    );

    if (response.statusCode == 201) {
      return {'ok': true, 'message': 'Usuario creado con éxito'};
    } else {
      final error = jsonDecode(response.body);
      return {'ok': false, 'error': error['error'] ?? 'Error desconocido'};
    }
  }

  // OBTENER ID DE USUARIO DESDE EL TOKEN
  static Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final data = jsonDecode(payload);
    return int.tryParse(data['sub'].toString());
  }

  static Future<String?> getUsernameFromToken(String? token) async {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final data = jsonDecode(payload);
    return data['username'];
  }
}
