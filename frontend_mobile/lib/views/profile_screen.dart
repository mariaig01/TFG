import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'post_detail_screen.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/user.dart';
import '../env.dart';
import '../widgets/bottom_nav_bar.dart';
import 'feed_screen.dart';
import 'miarmario_screen.dart';
import 'search_screen.dart';
import 'create_post_screen.dart';
import 'perfil_usuario_screen.dart';
import 'configuracion_screen.dart';
import 'prenda_detail_screen.dart';
import '../models/prenda.dart';
import '../models/post.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPerfilDesdeToken();
    });
  }

  void _cargarPerfilDesdeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      final userId = _getUserIdFromToken(token);
      if (userId != null) {
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).cargarPerfil(userId);
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).cargarMisPublicaciones();
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).cargarPublicacionesGuardadas();

        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).cargarPrendasGuardadas();
        setState(() {});
      }
    }
  }

  int? _getUserIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final data = jsonDecode(payload);
    return int.tryParse(data['sub'].toString());
  }

  void _mostrarListaUsuarios(String titulo, List<UserModel> usuarios) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final u = usuarios[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  u.fotoPerfil != null
                                      ? NetworkImage('$baseURL${u.fotoPerfil}')
                                      : null,
                              child:
                                  u.fotoPerfil == null
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                            title: Text(u.username),
                            subtitle: Text(u.nombre ?? ''),
                            onTap: () {
                              Navigator.pop(context); // Cierra el modal
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PerfilUsuarioScreen(userId: u.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _editarFotoPerfil() async {
    final ok =
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).subirImagenPerfil();

    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al subir la imagen")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ProfileViewModel>(context);
    final user = vm.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFFFFB5B2)),
          onPressed: () async {
            final actualizado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
            );

            if (actualizado == true) {
              _cargarPerfilDesdeToken(); // 🔄 Vuelve a cargar el perfil actualizado
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFFFB5B2)),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // o el índice actual
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
              break;
          }
        },
      ),
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
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
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _editarFotoPerfil,
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

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap:
                                () => _mostrarListaUsuarios(
                                  "Seguidores",
                                  vm.listaSeguidores,
                                ),
                            child: Text(
                              '${vm.seguidores} seguidores',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => _mostrarListaUsuarios(
                                  "Seguidos",
                                  vm.listaSeguidos,
                                ),
                            child: Text(
                              '${vm.seguidos} seguidos',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => _mostrarListaUsuarios(
                                  "Amigos",
                                  vm.listaAmigos,
                                ),
                            child: Text(
                              '${vm.amigos} amigos',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.bio ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Tabs
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xFFFFB5B2),
                          tabs: [
                            Tab(text: "Publicaciones"),
                            Tab(text: "Guardado"),
                          ],
                        ),
                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            children: [_buildGridPosts(), _buildGridSaved()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildGridPosts() {
    final publicaciones =
        Provider.of<ProfileViewModel>(context).publicacionesPropias;

    if (publicaciones.isEmpty) {
      return const Center(child: Text("No has subido publicaciones aún"));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children:
            publicaciones.map((post) {
              return GestureDetector(
                onTap: () async {
                  final recargar = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  );

                  if (recargar == true) {
                    // 🔄 Recargar perfil y publicaciones
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('jwt_token');
                    if (token != null) {
                      final parts = token.split('.');
                      final payload = utf8.decode(
                        base64Url.decode(base64Url.normalize(parts[1])),
                      );
                      final data = jsonDecode(payload);
                      final userId = int.tryParse(data['sub'].toString());
                      if (userId != null) {
                        final vm = Provider.of<ProfileViewModel>(
                          context,
                          listen: false,
                        );
                        vm.cargarPerfil(userId);
                        vm.cargarMisPublicaciones();
                        vm.cargarPublicacionesGuardadas();
                        vm.cargarPrendasGuardadas();
                      }
                    }
                  }
                },

                child: Image.network(
                  post.imagenUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(color: Colors.grey[300]),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildGridSaved() {
    final vm = Provider.of<ProfileViewModel>(context);
    final publicaciones = vm.publicacionesGuardadas;
    final prendas = vm.prendasGuardadas;

    final combinadas = <Map<String, dynamic>>[
      ...publicaciones.map((p) => {'tipo': 'post', 'data': p}),
      ...prendas.map((p) => {'tipo': 'prenda', 'data': p}),
    ];

    if (combinadas.isEmpty) {
      return const Center(
        child: Text("No has guardado publicaciones ni prendas aún"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children:
            combinadas.map((item) {
              final String tipo = item['tipo'];
              final dynamic data = item['data'];

              return GestureDetector(
                onTap: () async {
                  if (tipo == 'post' && data is PostModel) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: data),
                      ),
                    );
                  } else if (tipo == 'prenda' && data is Prenda) {
                    final userId = data.usuarioId;
                    if (userId != null) {
                      final relacion = await vm.obtenerRelacionConUsuario(
                        userId,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PrendaDetailScreen(
                                prenda: data,
                                relacionConUsuario: relacion,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Error: esta prenda no tiene usuario asociado.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Image.network(
                  (tipo == 'post'
                          ? (data as PostModel).imagenUrl
                          : (data as Prenda).imagenUrl) ??
                      '',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(color: Colors.grey[300]),
                ),
              );
            }).toList(),
      ),
    );
  }
}
