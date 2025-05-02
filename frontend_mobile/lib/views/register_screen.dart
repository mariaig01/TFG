import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController apellidoCtrl = TextEditingController();

  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Crear cuenta"),
        backgroundColor: const Color(0xFFFFB5B2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Registro",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB5B2),
              ),
            ),
            const SizedBox(height: 40),

            // Nombre
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: "Nombre",
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

            // Apellidos
            TextField(
              controller: apellidoCtrl,
              decoration: InputDecoration(
                labelText: "Apellidos",
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

            // Nombre de usuario
            TextField(
              controller: usernameCtrl,
              decoration: InputDecoration(
                labelText: "Nombre de usuario",
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

            // Correo electrónico
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

            // Contraseña
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
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
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
            const SizedBox(height: 40),

            // Botón de registrar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final registerVM = Provider.of<RegisterViewModel>(
                    context,
                    listen: false,
                  );

                  bool success = await registerVM.register(
                    username: usernameCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    apellido: apellidoCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                  );
                  if (success) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => const AlertDialog(
                            title: Text("Verificación necesaria"),
                            content: Text(
                              "Se ha enviado un enlace de verificación a tu correo electrónico. "
                              "Por favor, accede a tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.",
                            ),
                          ),
                    );

                    // Esperar 10 segundos y luego cerrar diálogo y volver a LoginScreen
                    Future.delayed(const Duration(seconds: 10), () {
                      Navigator.pop(context); // cierra el diálogo
                      Navigator.pop(context); // vuelve a LoginScreen
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          registerVM.errorMessage ??
                              "Ocurrió un error inesperado",
                        ),
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
                  "Registrarse",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
