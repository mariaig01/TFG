// lib/views/miarmario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/miarmario_viewmodel.dart';
import '../widgets/armario_nav_bar.dart';
import 'feed_screen.dart';
import 'edit_prenda_screen.dart';
import 'graficos_costos_screen.dart';
import 'search_prendas_screen.dart';
import 'asistente_belleza_screen.dart';

class MiArmarioScreen extends StatefulWidget {
  const MiArmarioScreen({super.key});

  @override
  State<MiArmarioScreen> createState() => _MiArmarioScreenState();
}

class _MiArmarioScreenState extends State<MiArmarioScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MiArmarioViewModel>().cargarPrendas());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MiArmarioViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        title: const Text(
          "Mi Armario",
          style: TextStyle(color: Color(0xFFFFB5B2)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB5B2)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FeedScreen()),
            );
          },
        ),
      ),
      bottomNavigationBar: ArmarioNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            //IA
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GraficosCostosScreen()),
            );
          } else if (index == 2) {
            // mi armario
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AsistenteBellezaScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchPrendasScreen()),
            );
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: vm.colorSeleccionado,
                    hint: const Text("Color"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Color"),
                      ),
                      ...vm.colores.map(
                        (color) => DropdownMenuItem(
                          value: color,
                          child: Text(color, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: vm.seleccionarColor,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: vm.tipoSeleccionado,
                    hint: const Text("Tipo"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Tipo"),
                      ),
                      ...vm.tipos.map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: vm.seleccionarTipo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                        itemCount: vm.prendasFiltradas.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final prenda = vm.prendasFiltradas[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditPrendaScreen(prenda: prenda),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFFFB5B2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  prenda.imagenUrl ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
