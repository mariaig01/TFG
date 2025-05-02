import 'package:flutter/material.dart';
import '../viewmodels/prenda_detail_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PrendaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> prenda;
  final Map<String, dynamic>? relacionConUsuario;

  const PrendaDetailScreen({
    super.key,
    required this.prenda,
    required this.relacionConUsuario,
  });

  @override
  State<PrendaDetailScreen> createState() => _PrendaDetailScreenState();
}

class _PrendaDetailScreenState extends State<PrendaDetailScreen> {
  @override
  void initState() {
    super.initState();
    final vm = Provider.of<PrendaDetailViewModel>(context, listen: false);
    vm.verificarEstadoPrestamo(widget.prenda['id']);
  }

  bool puedeSolicitar(PrendaDetailViewModel vm) {
    final esAmigo =
        widget.relacionConUsuario?['relacion'] == 'amigo' &&
        widget.relacionConUsuario?['estado'] != 'pendiente';
    final esSolicitable = widget.prenda['solicitable'] == true;
    return esAmigo && esSolicitable && !vm.enPrestamo;
  }

  @override
  Widget build(BuildContext context) {
    final categorias = widget.prenda['categorias'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        title: const Text("Detalle de Prenda"),
        backgroundColor: const Color(0xFFFFB5B2),
      ),
      body: Consumer<PrendaDetailViewModel>(
        builder:
            (context, vm, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.prenda['imagen_url'],
                      fit: BoxFit.cover,
                      height: 300,
                      errorBuilder:
                          (_, __, ___) =>
                              Container(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCampo("Nombre", widget.prenda['nombre']),
                  _buildCampo("Descripción", widget.prenda['descripcion']),
                  _buildCampo("Precio", "${widget.prenda['precio']} €"),
                  _buildCampo("Talla", widget.prenda['talla']),
                  _buildCampo("Color", widget.prenda['color']),
                  _buildCampo("Estación", widget.prenda['estacion']),
                  _buildChipsCampo("Categorías", categorias),
                  const SizedBox(height: 20),
                  if (puedeSolicitar(vm))
                    ElevatedButton(
                      onPressed: () => _mostrarDialogoSolicitud(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB5B2),
                      ),
                      child: const Text("Solicitar prenda"),
                    )
                  else if (widget.relacionConUsuario?['relacion'] == 'amigo' &&
                      vm.enPrestamo)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text("No disponible"),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Prenda en préstamo hasta: ${DateFormat('dd/MM/yyyy HH:mm').format(vm.fechaFinPrestamo!)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _mostrarDialogoSolicitud(BuildContext context) async {
    final now = DateTime.now();
    DateTime? fechaInicio;
    DateTime? fechaFin;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Solicitar préstamo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      fechaInicio != null
                          ? 'Inicio: ${fechaInicio.toString()}'
                          : 'Seleccionar fecha y hora de inicio',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (date == null) return;

                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                      );
                      if (time == null) return;

                      final combined = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );

                      setModalState(() => fechaInicio = combined);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(
                      fechaFin != null
                          ? 'Fin: ${fechaFin.toString()}'
                          : 'Seleccionar fecha y hora de fin',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (date == null) return;

                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                      );
                      if (time == null) return;

                      final combined = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );

                      setModalState(() => fechaFin = combined);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    if (fechaInicio != null && fechaFin != null) {
                      final vm = Provider.of<PrendaDetailViewModel>(
                        context,
                        listen: false,
                      );
                      await vm.solicitarPrenda(
                        widget.prenda['id'],
                        fechaInicio: fechaInicio!,
                        fechaFin: fechaFin!,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            vm.errorMessage ??
                                vm.successMessage ??
                                "Error desconocido",
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Solicitar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCampo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFFB5B2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value ?? '-', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsCampo(String label, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFFB5B2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  items.map((e) => Chip(label: Text(e.toString()))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
