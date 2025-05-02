import 'dart:io';
import 'feed_screen.dart';
import 'miarmario_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/create_prenda_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'create_post_screen.dart';

class CreatePrendaScreen extends StatefulWidget {
  const CreatePrendaScreen({super.key});

  @override
  State<CreatePrendaScreen> createState() => _CreatePrendaScreenState();
}

class _CreatePrendaScreenState extends State<CreatePrendaScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController tallaController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController categoriaInputController =
      TextEditingController();
  final List<String> estaciones = [
    'Primavera',
    'Verano',
    'Otoño',
    'Invierno',
    'Cualquiera',
  ];

  final List<String> emociones = [
    'feliz',
    'triste',
    'enfadado',
    'sorprendido',
    'miedo',
    'asco',
    'neutro',
  ];

  List<String> categorias = [];
  String? estacionSeleccionada;
  File? imagenSeleccionada;
  bool fondoBlanco = true;
  bool solicitable = false;

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<CreatePrendaViewModel>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.cargarTiposDesdeBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CreatePrendaViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onNavigate: (context, index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FeedScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MiArmarioScreen()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFB5B2)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreatePostScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Publicación",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB5B2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB5B2),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Prenda",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: seleccionarImagen,
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
                      imagenSeleccionada != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              imagenSeleccionada!,
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
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  hintText: "Nombre",
                  hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  hintText: "Descripción",
                  hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<CreatePrendaViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.cargandoTipos) {
                    return const CircularProgressIndicator();
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Tipo de prenda',
                      labelStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFFB5B2),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: viewModel.tipoSeleccionado,
                    items:
                        viewModel.tiposPrenda.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                    onChanged: (value) {
                      viewModel.tipoSeleccionado = value!;
                    },
                  );
                },
              ),

              const SizedBox(height: 12),
              TextField(
                controller: precioController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: "Precio",
                  hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tallaController,
                decoration: InputDecoration(
                  hintText: "Talla",
                  hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      color: Color(0xFFFFB5B2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        categorias
                            .map(
                              (cat) => Chip(
                                label: Text(cat),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () {
                                  setState(() {
                                    categorias.remove(cat);
                                  });
                                },
                                backgroundColor: const Color(
                                  0xFFFFB5B2,
                                ).withOpacity(0.2),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoriaInputController,
                    decoration: InputDecoration(
                      hintText: "Escribe y pulsa Enter...",
                      hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFFB5B2),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      final newValue = value.trim();
                      if (newValue.isNotEmpty &&
                          !categorias.contains(newValue)) {
                        setState(() {
                          categorias.add(newValue);
                          categoriaInputController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: vm.emocionSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Emoción',
                  labelStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    emociones.map((emocion) {
                      return DropdownMenuItem<String>(
                        value: emocion,
                        child: Text(
                          emocion[0].toUpperCase() + emocion.substring(1),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    vm.emocionSeleccionada = value!;
                  });
                },
              ),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Estación',
                  labelStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: estacionSeleccionada,
                items:
                    estaciones
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    estacionSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: InputDecoration(
                  hintText: "Color",
                  hintStyle: const TextStyle(color: Color(0xFFFFB5B2)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFB5B2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB5B2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Solicitable",
                    style: TextStyle(color: Color(0xFFFFB5B2)),
                  ),
                  Switch(
                    value: solicitable,
                    onChanged: (value) {
                      setState(() {
                        solicitable = value;
                      });
                    },
                    activeColor: const Color(0xFFFFB5B2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Eliminar fondo",
                    style: TextStyle(color: Color(0xFFFFB5B2)),
                  ),
                  Switch(
                    value: fondoBlanco,
                    onChanged: (value) {
                      setState(() {
                        fondoBlanco = value;
                      });
                    },
                    activeColor: const Color(0xFFFFB5B2),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await vm.createPrenda(
                      nombre: nombreController.text.trim(),
                      descripcion: descripcionController.text.trim(),
                      precio: double.tryParse(precioController.text) ?? 0.0,
                      talla: tallaController.text.trim(),
                      color: colorController.text.trim(),
                      solicitable: solicitable,
                      imagen: imagenSeleccionada,
                      eliminarFondo: fondoBlanco,
                      categorias: categorias,
                      estacion: estacionSeleccionada ?? 'Cualquiera',
                    );

                    if (vm.errorMessage == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MiArmarioScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB5B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Guardar prenda",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
