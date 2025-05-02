import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/configuracion_viewmodel.dart'; // SettingsViewModel
import '../env.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final bioController = TextEditingController();
  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<ProfileViewModel>(context, listen: false);
    if (vm.user != null) {
      nombreController.text = vm.user!.nombre ?? '';
      apellidoController.text = vm.user!.apellido ?? '';
      bioController.text = vm.user!.bio ?? '';
      usernameController.text = vm.user!.username;
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    bioController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final settingsVM = Provider.of<SettingsViewModel>(context, listen: false);
    await settingsVM.seleccionarImagenDesdeGaleria();
  }

  Future<void> _actualizarPerfil() async {
    final settingsVM = Provider.of<SettingsViewModel>(context, listen: false);

    final exitoFoto = await settingsVM.subirNuevaFotoPerfil();
    if (!exitoFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al subir la nueva imagen")),
      );
      return;
    }

    final resultado = await settingsVM.actualizarDatosPerfil(
      nombre: nombreController.text.trim(),
      apellido: apellidoController.text.trim(),
      bio: bioController.text.trim(),
      username: usernameController.text.trim(),
    );

    if (resultado['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado con éxito")),
      );
      Navigator.pop(context, true); // Devolver true al ProfileScreen
    } else {
      final mensajeError = resultado['error'] ?? "Error al actualizar perfil";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<ProfileViewModel>(context);
    final settingsVM = Provider.of<SettingsViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB5B2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(color: Color(0xFFFFB5B2)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        settingsVM.nuevaImagen != null
                            ? FileImage(
                              settingsVM.nuevaImagen!,
                            ) // si eligió nueva imagen local
                            : (profileVM.user?.fotoPerfil != null
                                    ? NetworkImage(
                                      '$baseURL${profileVM.user!.fotoPerfil}',
                                    ) // sino, la del backend
                                    : null)
                                as ImageProvider<Object>?,
                    backgroundColor: const Color(0xFFFFB5B2),
                    child:
                        settingsVM.nuevaImagen == null &&
                                profileVM.user?.fotoPerfil == null
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            )
                            : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _seleccionarImagen,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildTextField(nombreController, 'Nombre'),
              const SizedBox(height: 16),
              _buildTextField(apellidoController, 'Apellidos'),
              const SizedBox(height: 16),
              _buildTextField(bioController, 'Bio'),
              const SizedBox(height: 16),
              _buildTextField(usernameController, 'Nombre de usuario'),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB5B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                onPressed: _actualizarPerfil,
                child: const Text(
                  'Actualizar perfil',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
