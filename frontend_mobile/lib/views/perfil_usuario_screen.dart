import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/perfil_usuario_viewmodel.dart';
import '../viewmodels/search_viewmodel.dart';
import '../env.dart';
import 'post_detail_screen.dart';
import 'prenda_detail_screen.dart';
import 'direct_messages_screen.dart';
import '../viewmodels/direct_messages_viewmodel.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  final int userId;
  const PerfilUsuarioScreen({super.key, required this.userId});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<PerfilUsuarioViewModel>().cargarTodo(widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilUsuarioViewModel>();
    final searchVM = context.read<SearchViewModel>();
    final user = vm.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        leading: const BackButton(color: Color(0xFFFFB5B2)),
      ),
      backgroundColor: const Color(0xFFFFF0F0),
      body:
          vm.isLoading || user == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        user['foto_perfil'] != null
                            ? NetworkImage('$baseURL${user['foto_perfil']}')
                            : null,
                    backgroundColor: const Color(0xFFFFB5B2),
                    child:
                        user['foto_perfil'] == null
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (user['bio'] != null)
                    Text(
                      user['bio'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRelacionButton(
                        tipo: 'seguidor',
                        usuario: user,
                        vm: searchVM,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(width: 10),
                      _buildRelacionButton(
                        tipo: 'amigo',
                        usuario: user,
                        vm: searchVM,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider(
                                create: (_) => DirectMessagesViewModel(),
                                child: DirectMessagesScreen(
                                  usuario: {
                                    'id': user['id'],
                                    'username': user['username'],
                                    'foto_perfil':
                                        user['foto_perfil'] != null
                                            ? '$baseURL${user['foto_perfil']}'
                                            : null,
                                  },
                                ),
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text(
                      'Enviar mensaje',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB5B2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: const [
                          TabBar(
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Color(0xFFFFB5B2),
                            tabs: [
                              Tab(text: "Publicaciones"),
                              Tab(text: "Prendas"),
                            ],
                          ),
                          Expanded(child: _TabContenido()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildRelacionButton({
    required String tipo,
    required Map<String, dynamic> usuario,
    required dynamic vm,
    required VoidCallback onChanged,
  }) {
    final relacion = usuario['relacion'];
    final estado = usuario['estado'];
    final estadoSeguidor = usuario['estado_seguidor'];

    final esRelacion =
        relacion == tipo ||
        (tipo == 'seguidor' && estadoSeguidor == 'pendiente');
    final esPendiente =
        (estado == 'pendiente' && relacion == tipo) ||
        (tipo == 'seguidor' && estadoSeguidor == 'pendiente');

    String label;
    if (esPendiente) {
      label = '🕘 ${tipo == 'amigo' ? 'Amistad' : 'Seguir'}';
    } else if (esRelacion) {
      label = '❌ ${tipo == 'amigo' ? 'Amistad' : 'Seguir'}';
    } else {
      label = tipo == 'amigo' ? 'Amistad' : 'Seguir';
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFB5B2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () async {
        final yaTiene = esRelacion;
        final ok =
            yaTiene
                ? await vm.eliminarRelacion(usuario['id'], tipo: tipo)
                : await vm.enviarSolicitud(usuario['id'], tipo: tipo);

        if (ok) {
          await context.read<PerfilUsuarioViewModel>().cargarTodo(
            widget.userId,
          );
          onChanged();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? yaTiene
                      ? 'Has cancelado la solicitud de $tipo'
                      : 'Solicitud de $tipo enviada a ${usuario['username']}'
                  : 'Error al procesar la acción',
            ),
          ),
        );
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _TabContenido extends StatelessWidget {
  const _TabContenido();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PerfilUsuarioViewModel>(context);
    final user = vm.user;

    final relacion = user?['relacion'];
    final estado = user?['estado'];

    final accesoPorRelacion =
        (relacion == 'amigo' && estado == 'aceptada') ||
        (relacion == 'seguidor' && estado == 'aceptada');

    final tieneAcceso = accesoPorRelacion;

    if (!tieneAcceso) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No sigues ni eres amigo de este usuario.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return TabBarView(
      children: [
        _GridItems(items: vm.publicaciones, tipo: 'post'),
        _GridItems(items: vm.prendas, tipo: 'prenda'),
      ],
    );
  }
}

class _GridItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String tipo;

  const _GridItems({required this.items, required this.tipo});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("Sin contenido"));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children:
            items.map((item) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              tipo == 'post'
                                  ? PostDetailScreen(post: item)
                                  : PrendaDetailScreen(
                                    prenda: item,
                                    relacionConUsuario:
                                        Provider.of<PerfilUsuarioViewModel>(
                                          context,
                                          listen: false,
                                        ).user,
                                  ),
                    ),
                  );
                },
                child: Image.network(
                  item['imagen_url'],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
      ),
    );
  }
}
