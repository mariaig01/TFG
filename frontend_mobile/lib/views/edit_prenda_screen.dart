import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/edit_prenda_viewmodel.dart';
import 'miarmario_screen.dart';
import 'package:flutter/services.dart';

class EditPrendaScreen extends StatefulWidget {
  final Map<String, dynamic> prenda;

  const EditPrendaScreen({super.key, required this.prenda});

  @override
  State<EditPrendaScreen> createState() => _EditPrendaScreenState();
}

class _EditPrendaScreenState extends State<EditPrendaScreen> {
  late TextEditingController nombreController;
  late TextEditingController descripcionController;
  late TextEditingController precioController;
  late TextEditingController tallaController;
  late TextEditingController colorController;
  late TextEditingController categoriaInputController;

  bool solicitable = false;
  String? estacionSeleccionada;
  List<String> categorias = [];
  String? tipoSeleccionado;

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
  String? _emocionSeleccionada = 'neutro';

  @override
  void initState() {
    super.initState();
    final p = widget.prenda;
    nombreController = TextEditingController(text: p['nombre']);
    descripcionController = TextEditingController(text: p['descripcion']);
    precioController = TextEditingController(text: p['precio'].toString());
    tallaController = TextEditingController(text: p['talla']);
    colorController = TextEditingController(text: p['color']);
    categoriaInputController = TextEditingController();
    solicitable = p['solicitable'] ?? false;
    categorias = List<String>.from(p['categorias'] ?? []);
    estacionSeleccionada = p['estacion'] ?? 'Cualquiera';
    tipoSeleccionado = p['tipo'] ?? 'Otro';

    Future.microtask(
      () =>
          Provider.of<EditPrendaViewModel>(
            context,
            listen: false,
          ).cargarTipos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditPrendaViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar prenda"),
        backgroundColor: const Color(0xFFFFB5B2),
      ),
      backgroundColor: const Color(0xFFFFF0F0),
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.prenda['imagen_url'],
                        fit: BoxFit.contain,
                        height: 300,
                        width: double.infinity,
                        errorBuilder:
                            (_, __, ___) =>
                                Container(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(nombreController, "Nombre"),
                    const SizedBox(height: 10),
                    _buildTextField(descripcionController, "Descripción"),
                    const SizedBox(height: 10),
                    _buildTextField(
                      precioController,
                      "Precio",
                      isNumeric: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(tallaController, "Talla"),
                    const SizedBox(height: 10),
                    _buildTextField(colorController, "Color"),
                    const SizedBox(height: 10),
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB5B2),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          categorias
                              .map(
                                (cat) => Chip(
                                  label: Text(cat),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted:
                                      () => setState(
                                        () => categorias.remove(cat),
                                      ),
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
                      decoration: _inputDecoration("Escribe y pulsa Enter..."),
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Estación'),
                      value: estacionSeleccionada,
                      items:
                          estaciones
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              setState(() => estacionSeleccionada = value),
                    ),
                    const SizedBox(height: 10),
                    vm.loadingTipos
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Tipo de prenda'),
                          value: tipoSeleccionado,
                          items:
                              vm.tiposPrenda
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => tipoSeleccionado = value),
                        ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _emocionSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Emoción',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          emociones.map((emocion) {
                            return DropdownMenuItem(
                              value: emocion,
                              child: Text(
                                emocion[0].toUpperCase() + emocion.substring(1),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _emocionSeleccionada = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Solicitable",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: solicitable,
                          onChanged:
                              (value) => setState(() => solicitable = value),
                          activeColor: const Color(0xFFFFB5B2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        final ok = await vm.actualizarPrenda(
                          id: widget.prenda['id'],
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          precio: double.tryParse(precioController.text) ?? 0.0,
                          talla: tallaController.text.trim(),
                          color: colorController.text.trim(),
                          solicitable: solicitable,
                          categorias: categorias,
                          estacion: estacionSeleccionada ?? 'Cualquiera',
                          tipo: tipoSeleccionado ?? 'Otro',
                          emocion: _emocionSeleccionada ?? 'neutro',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              vm.errorMessage ??
                                  vm.successMessage ??
                                  'Error inesperado',
                            ),
                          ),
                        );

                        if (ok) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MiArmarioScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB5B2),
                      ),
                      child: const Text("Guardar cambios"),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => _confirmarEliminacion(context, vm),
                      child: const Text(
                        "Eliminar prenda",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumeric
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      inputFormatters:
          isNumeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
              : [],
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFFFB5B2), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, EditPrendaViewModel vm) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Eliminar prenda?"),
            content: const Text("Esta acción no se puede deshacer."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final ok = await vm.eliminarPrenda(widget.prenda['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vm.errorMessage ??
                            vm.successMessage ??
                            'Error inesperado',
                      ),
                    ),
                  );
                  if (ok) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MiArmarioScreen(),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
