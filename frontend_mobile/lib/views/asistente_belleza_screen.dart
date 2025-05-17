import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../viewmodels/asistente_belleza_viewmodel.dart';
import '../widgets/armario_nav_bar.dart';
import 'feed_screen.dart';
import 'graficos_costos_screen.dart';
import 'miarmario_screen.dart';
import 'search_prendas_screen.dart';

class AsistenteBellezaScreen extends StatelessWidget {
  const AsistenteBellezaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AsistenteBellezaViewModel(),
      child: const _AsistenteBellezaContent(),
    );
  }
}

class _AsistenteBellezaContent extends StatefulWidget {
  const _AsistenteBellezaContent();

  @override
  State<_AsistenteBellezaContent> createState() =>
      _AsistenteBellezaContentState();
}

class _AsistenteBellezaContentState extends State<_AsistenteBellezaContent> {
  File? selectedImage;

  int _hexToColorInt(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha value if not present
    }
    return int.parse(hexColor, radix: 16);
  }

  Future<bool> _checkPermissions() async {
    var status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<void> _pickImage() async {
    final granted = await _checkPermissions();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de galería denegado')),
      );
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });

      final vm = Provider.of<AsistenteBellezaViewModel>(context, listen: false);
      await vm.analizarFoto(selectedImage!);
    }
  }

  void _mostrarDialogo(BuildContext context, String titulo, Widget contenido) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              titulo,
              style: const TextStyle(color: Color(0xFFFFB5B2)),
            ),
            content: contenido,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Color(0xFFFFB5B2)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _botonRecomendacion(String texto, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFB5B2),
          side: const BorderSide(color: Color(0xFFFFB5B2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AsistenteBellezaViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB5B2)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FeedScreen()),
            );
          },
        ),
        title: const Text(
          "Asistente de Belleza",
          style: TextStyle(color: Color(0xFFFFB5B2)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      selectedImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                          : const Icon(
                            Icons.image_outlined,
                            color: Color(0xFFFFB5B2),
                            size: 100,
                          ),
                ),
              ),
              const SizedBox(height: 30),
              if (vm.isLoading)
                const CircularProgressIndicator()
              else
                const SizedBox.shrink(),

              const SizedBox(height: 30),

              _botonRecomendacion("Colorimetría", () {
                _mostrarDialogo(
                  context,
                  "Colorimetría",
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.tonoPiel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Tono de piel detectado: ${vm.tonoPiel}\nSubestación detectada: ${vm.subEstacion}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (vm.coloresRecomendados.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              vm.coloresRecomendados.map((color) {
                                return CircleAvatar(
                                  backgroundColor: Color(_hexToColorInt(color)),
                                  radius: 16,
                                );
                              }).toList(),
                        )
                      else
                        const Text("No hay recomendaciones disponibles."),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),
              _botonRecomendacion("Estilo de corte de pelo ", () {
                _mostrarDialogo(
                  context,
                  "Estilo de corte de pelo",
                  Text(vm.peinados ?? "No hay recomendaciones disponibles."),
                );
              }),
              const SizedBox(height: 12),
              _botonRecomendacion("Consejos de maquillaje", () {
                _mostrarDialogo(
                  context,
                  "Makeup Tips",
                  Text(vm.maquillaje ?? "No hay recomendaciones disponibles."),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ArmarioNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            // IA
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => GraficosCostosScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MiArmarioScreen()),
            );
          } else if (index == 3) {
            // Ya estás aquí
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SearchPrendasScreen()),
            );
          }
        },
      ),
    );
  }
}
