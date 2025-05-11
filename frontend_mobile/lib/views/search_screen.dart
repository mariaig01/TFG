import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_viewmodel.dart';
import '../env.dart';
import '../viewmodels/group_viewmodel.dart';
import 'feed_screen.dart';
import 'miarmario_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'create_post_screen.dart';
import 'perfil_usuario_screen.dart';
import 'group_messages_screen.dart';
import '../models/group.dart';
import '../models/user.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchViewModel>(context, listen: false).limpiarResultados();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SearchViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Buscar", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // o el índice actual
        onNavigate: (context, index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FeedScreen()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Color(0xFFFFB5B2), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Buscar usuarios o grupos",
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          vm.buscar(value);
                        } else {
                          vm.limpiarResultados();
                        }
                      },
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFFFFB5B2)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        children: [
                          if (vm.usuarios.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Usuarios",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ...vm.usuarios.map(
                            (usuario) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    usuario.fotoPerfil != null
                                        ? NetworkImage(usuario.fotoPerfil!)
                                        : null,
                                child:
                                    usuario.fotoPerfil == null
                                        ? const Icon(Icons.person)
                                        : null,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PerfilUsuarioScreen(
                                          userId: usuario.id,
                                        ),
                                  ),
                                );
                              },
                              title: Text(usuario.username),
                              subtitle: Row(
                                children: [
                                  _buildRelacionButton(
                                    tipo: 'seguidor',
                                    usuario: usuario,
                                    vm: vm,
                                    onChanged: () => setState(() {}),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildRelacionButton(
                                    tipo: 'amigo',
                                    usuario: usuario,
                                    vm: vm,
                                    onChanged: () => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (vm.grupos.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Grupos",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ...vm.grupos.map(
                            (grupo) => ListTile(
                              leading:
                                  grupo.fotoUrl != null
                                      ? CircleAvatar(
                                        backgroundImage:
                                            grupo.fotoUrl != null
                                                ? NetworkImage(grupo.fotoUrl!)
                                                : null,
                                      )
                                      : const CircleAvatar(
                                        child: Icon(Icons.group),
                                      ),
                              title: Text(grupo.nombre),
                              onTap: () {
                                if (grupo.esMiembro == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => GroupMessagesScreen(
                                            group: GroupModel(
                                              id: grupo.id.toString(),
                                              nombre: grupo.nombre,
                                              fotoUrl:
                                                  grupo.fotoUrl != null
                                                      ? '$baseURL${grupo.fotoUrl}'
                                                      : null,
                                            ),
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Debes unirte al grupo para ver los mensajes.',
                                      ),
                                    ),
                                  );
                                }
                              },

                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB5B2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () async {
                                  final groupVM = Provider.of<GroupViewModel>(
                                    context,
                                    listen: false,
                                  );
                                  bool ok;
                                  if (grupo.esMiembro == true) {
                                    ok = await groupVM.abandonarGrupo(
                                      int.parse(grupo.id),
                                    );
                                    if (ok)
                                      grupo = grupo.copyWith(esMiembro: false);
                                  } else {
                                    ok = await groupVM.unirseAGrupo(
                                      int.parse(grupo.id),
                                    );
                                    if (ok)
                                      grupo = grupo.copyWith(esMiembro: true);
                                  }
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? grupo.esMiembro == true
                                                ? 'Te has unido al grupo ${grupo.nombre}'
                                                : 'Has abandonado el grupo ${grupo.nombre}'
                                            : 'Error en la operación',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  grupo.esMiembro == true
                                      ? 'Abandonar'
                                      : 'Unirse',
                                ),
                              ),
                            ),
                          ),

                          if (vm.usuarios.isEmpty &&
                              vm.grupos.isEmpty &&
                              _controller.text.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text("No se encontraron resultados."),
                            ),
                        ],
                      ),
            ),
          ],
        ),
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
          await context.read<SearchViewModel>().actualizarRelacionUsuario(
            usuario.id,
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
