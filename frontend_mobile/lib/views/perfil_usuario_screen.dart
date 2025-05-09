import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/perfil_usuario_viewmodel.dart';
import '../viewmodels/search_viewmodel.dart';
import 'post_detail_screen.dart';
import 'prenda_detail_screen.dart';
import 'direct_messages_screen.dart';
import '../viewmodels/direct_messages_viewmodel.dart';
import '../models/prenda.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../env.dart';

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
                        user.fotoPerfil != null
                            ? NetworkImage('$baseURL${user.fotoPerfil}')
                            : null,
                    backgroundColor: const Color(0xFFFFB5B2),
                    child:
                        user.fotoPerfil == null
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (user.bio != null)
                    Text(user.bio!, style: const TextStyle(color: Colors.grey)),
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
                                  usuario: UserModel(
                                    id: user.id,
                                    username: user.username,
                                    nombre: user.nombre,
                                    fotoPerfil: user.fotoPerfil,
                                  ),
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
    required UserModel? usuario,
    required dynamic vm,
    required VoidCallback onChanged,
  }) {
    final relacion = usuario?.tipo ?? '';
    final estado = usuario?.estado ?? '';
    final estadoSeguidor = usuario?.estadoSeguidor ?? '';

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
                ? await vm.eliminarRelacion(usuario!.id, tipo: tipo)
                : await vm.enviarSolicitud(usuario!.id, tipo: tipo);

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
                      : 'Solicitud de $tipo enviada a ${usuario.username}'
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

    final relacion = user?.tipo ?? '';
    final estado = user?.estado ?? '';

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
        _GridItems<PostModel>(
          items: vm.publicaciones.toList(),
          onTap: (context, post) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
        ),
        _GridItems<Prenda>(
          items: vm.prendas.toList(),
          onTap: (context, prenda) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PrendaDetailScreen(
                      prenda: prenda,
                      relacionConUsuario: vm.user,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GridItems<T> extends StatelessWidget {
  final List<T> items;
  final void Function(BuildContext, T) onTap;

  const _GridItems({required this.items, required this.onTap});

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
              final String? imageUrl;
              if (item is PostModel) {
                imageUrl = item.imagenUrl;
              } else if (item is Prenda) {
                imageUrl = item.imagenUrl;
              } else {
                imageUrl = null;
              }

              return GestureDetector(
                onTap: () => onTap(context, item),
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Container(color: Colors.grey.shade300),
                        )
                        : Container(color: Colors.grey.shade300),
              );
            }).toList(),
      ),
    );
  }
}
