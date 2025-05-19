import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../env.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsViewModel>(
        context,
        listen: false,
      ).fetchSolicitudes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        backgroundColor: const Color(0xFFFFB5B2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ToggleButtons(
            isSelected: [selectedIndex == 0, selectedIndex == 1],
            onPressed: (index) {
              setState(() => selectedIndex = index);
            },
            borderRadius: BorderRadius.circular(20),
            fillColor: const Color(0xFFFFB5B2),
            color: Colors.black87,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Solicitudes"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Descuentos"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child:
                selectedIndex == 0 ? _buildSolicitudes() : _buildDescuentos(),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudes() {
    return Consumer<NotificationsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.solicitudes.isEmpty) {
          return const Center(child: Text("No tienes solicitudes pendientes."));
        }

        return ListView.builder(
          itemCount: vm.solicitudes.length,
          itemBuilder: (context, index) {
            final s = vm.solicitudes[index];
            final tipo =
                s["tipo"] == "amigo"
                    ? "Amistad"
                    : s["tipo"] == "seguidor"
                    ? "Seguimiento"
                    : s["tipo"] == "prenda"
                    ? "Prenda"
                    : "Desconocido";

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    s["foto_perfil"] != null
                        ? NetworkImage('$baseURL${s["foto_perfil"]}')
                        : null,
                child:
                    s["foto_perfil"] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(s["username"] ?? "Usuario desconocido"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Solicitud de $tipo"),
                  if (s["tipo"] == "prenda")
                    Text(
                      "Prenda: ${s["prenda"]?["nombre"] ?? ""}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              onTap: () {
                if (s["tipo"] == "prenda" && s["prenda"] != null) {
                  final prenda = s["prenda"];
                  showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: Text(
                            "Prenda: ${prenda["nombre"] ?? "Prenda"}",
                          ),

                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (prenda["imagen_url"] != null)
                                Image.network(
                                  '$baseURL${prenda["imagen_url"]}',
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              else
                                const Text("Sin imagen disponible"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cerrar"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                  );
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await vm.responderSolicitud(
                        s["id"].toString(),
                        s["tipo"],
                        aceptar: true,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Solicitud de ${s["tipo"]} aceptada."),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await vm.responderSolicitud(
                        s["id"],
                        s["tipo"],
                        aceptar: false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Solicitud de $tipo rechazada."),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDescuentos() {
    return const Center(
      child: Text("No hay descuentos disponibles en este momento."),
    );
  }
}
