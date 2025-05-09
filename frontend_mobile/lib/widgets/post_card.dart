import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../views/comments_screen.dart';
import '../viewmodels/likes_viewmodel.dart';
import '../viewmodels/messages_viewmodel.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../views/perfil_usuario_screen.dart';
import '../services/likes_notifier.dart';
import '../services/favorites_notifier.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final void Function(PostModel updatedPost)? onLikeToggled;
  final void Function(PostModel updatedPost)? onSaveToggled;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeToggled,
    this.onSaveToggled,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      setState(() {
        _post = widget.post;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final likesVM = Provider.of<LikeViewModel>(context);
    final mensajesVM = Provider.of<MessagesViewModel>(context);
    final groupVM = Provider.of<GroupViewModel>(context);
    final likesNotifier = Provider.of<LikesNotifier>(context);

    final bool isLiked = likesNotifier.isLiked(_post.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PerfilUsuarioScreen(userId: _post.idUsuario),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        _post.fotoPerfil != null
                            ? NetworkImage(_post.fotoPerfil!)
                            : null,
                    backgroundColor: Colors.pink[100],
                    child:
                        _post.fotoPerfil == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PerfilUsuarioScreen(userId: _post.idUsuario),
                      ),
                    );
                  },
                  child: Text(
                    _post.usuario,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (_post.tipoRelacion == 'seguido' ||
                    _post.tipoRelacion == 'amigo')
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB5B2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      _post.tipoRelacion == 'seguido' ? 'Seguido' : 'Amigo',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            if (_post.imagenUrl != null && _post.imagenUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _post.imagenUrl ?? '',
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) =>
                          const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.pink : Colors.grey,
                  ),
                  onPressed: () {
                    likesVM.toggleLike(_post, (updatedPost) {
                      likesNotifier.toggleLike(
                        updatedPost.id,
                        updatedPost.haDadoLike,
                        updatedPost.likesCount,
                      );

                      if (widget.onLikeToggled != null) {
                        widget.onLikeToggled!(updatedPost);
                      }

                      setState(() {
                        _post = updatedPost;
                      });
                    });
                  },
                ),
                Text('${likesNotifier.getLikesCount(_post.id)}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: _post.id),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () async {
                    await mensajesVM.fetchConversaciones();
                    await groupVM.loadGroupsForUser();

                    final usuarios = mensajesVM.usuarios;
                    final grupos = groupVM.groups;

                    if (usuarios.isEmpty && grupos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No hay usuarios ni grupos disponibles.',
                          ),
                        ),
                      );
                      return;
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        final TextEditingController mensajeController =
                            TextEditingController();

                        return Wrap(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                                top: 16,
                                left: 16,
                                right: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: mensajeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Añadir un mensaje',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                  ),
                                  const SizedBox(height: 12),
                                  if (usuarios.isNotEmpty)
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          "Usuarios",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ...usuarios.map(
                                    (usuario) => ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            usuario.fotoPerfil != null
                                                ? NetworkImage(
                                                  usuario.fotoPerfil!,
                                                )
                                                : null,
                                        child:
                                            usuario.fotoPerfil == null
                                                ? const Icon(Icons.person)
                                                : null,
                                      ),
                                      title: Text(usuario.username),
                                      subtitle: Text(usuario.tipo!),
                                      onTap: () async {
                                        await mensajesVM.enviarMensajeDirecto(
                                          receptorId: usuario.id,
                                          publicacionId: _post.id,
                                          mensaje:
                                              mensajeController.text.trim(),
                                        );
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Enviado a ${usuario.username}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (grupos.isNotEmpty)
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          top: 16,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          "Grupos",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ...grupos.map(
                                    (grupo) => ListTile(
                                      leading:
                                          grupo.fotoUrl != null
                                              ? CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  grupo.fotoUrl!,
                                                ),
                                              )
                                              : const CircleAvatar(
                                                child: Icon(Icons.group),
                                              ),
                                      title: Text(grupo.nombre),
                                      onTap: () async {
                                        await groupVM.enviarMensajeGrupo(
                                          grupoId: int.parse(grupo.id),
                                          idPublicacion: _post.id,
                                          mensaje:
                                              mensajeController.text.trim(),
                                        );
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Enviado al grupo ${grupo.nombre}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _post.guardado ? Icons.bookmark : Icons.bookmark_border,
                    color: _post.guardado ? Colors.pink : Colors.grey,
                  ),
                  onPressed: () async {
                    final favoritesVM = Provider.of<FavoritesViewModel>(
                      context,
                      listen: false,
                    );
                    final favoritesNotifier = Provider.of<FavoritesNotifier>(
                      context,
                      listen: false,
                    );
                    final feedVM = Provider.of<FeedViewModel>(
                      context,
                      listen: false,
                    );

                    final ok = await favoritesVM.toggleGuardarPublicacion(
                      _post.id,
                    );

                    if (ok) {
                      final nuevoGuardado = !_post.guardado;

                      // Actualizar en FavoritesNotifier
                      favoritesNotifier.toggleSave(_post.id, nuevoGuardado);

                      // Actualizar en FeedViewModel (base de datos local)
                      feedVM.actualizarEstadoGuardado(_post.id, nuevoGuardado);

                      // Actualizar el propio post local
                      final updatedPost = _post.copyWith(
                        guardado: nuevoGuardado,
                      );

                      if (widget.onSaveToggled != null) {
                        widget.onSaveToggled!(updatedPost);
                      }

                      setState(() {
                        _post = updatedPost;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_post.contenido, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
