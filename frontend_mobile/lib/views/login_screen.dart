import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../env.dart';
import '../viewmodels/login_viewmodel.dart';
import 'register_screen.dart';
import 'feed_screen.dart';
import 'forgotpassword_screen.dart';
import 'resetpassword_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool _passwordVisible = false;

  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _checkForDeepLink();
  }

  void _checkForDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVerifiedToken = prefs.getString('last_verified_token');

    final Uri? initialLink = await _appLinks.getInitialAppLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink, lastVerifiedToken);
    }

    _appLinks.uriLinkStream.listen((Uri? uri) async {
      final prefs = await SharedPreferences.getInstance();
      final lastVerifiedToken = prefs.getString('last_verified_token');

      if (uri != null) {
        _handleDeepLink(uri, lastVerifiedToken);
      }
    });
  }

  void _handleDeepLink(Uri uri, String? lastVerifiedToken) async {
    if (uri.scheme != 'looksy') return;

    final token = uri.queryParameters['token'];
    if (token == null) return;

    if (uri.host == 'verify') {
      if (token != lastVerifiedToken) {
        await _verificarCuenta(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_verified_token', token);
      }
    } else if (uri.host == 'reset') {
      // 🆕 Ir directamente a ResetPasswordScreen
      Future.microtask(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
        );
      });
    }
  }

  Future<void> _verificarCuenta(String token) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 80, color: Color(0xFFFFB5B2)),
                SizedBox(height: 20),
                Text("Verificando tu cuenta...", textAlign: TextAlign.center),
              ],
            ),
          ),
    );

    try {
      final res = await http.post(
        Uri.parse('$baseURL/auth/verify-email-mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      final body = jsonDecode(res.body);
      final mensaje = body['message'] ?? body['error'] ?? 'Error desconocido';

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al verificar la cuenta")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LoginViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/loginiconbg.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 30),
              const Text(
                "Iniciar sesión",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB5B2),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passCtrl,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Color(0xFFFFB5B2),
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),
              vm.isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        bool success = await vm.login(
                          emailCtrl.text,
                          passCtrl.text,
                        );
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Credenciales incorrectas"),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB5B2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Iniciar sesión",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: const Text(
                  "¿No tienes cuenta? Regístrate aquí",
                  style: TextStyle(color: Color(0xFFFFB5B2), fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(color: Color(0xFFFFB5B2), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
