import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';
import '../viewmodels/post_viewmodel.dart';
import '../services/likes_notifier.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int? userId;
  late PostModel postModel;
  late PostModel post;

  @override
  void initState() {
    super.initState();
    _decodeToken();
    postModel = PostModel(
      id: widget.post.id,
      contenido: widget.post.contenido,
      visibilidad: widget.post.visibilidad,
      imagenUrl: widget.post.imagenUrl,
      fecha: widget.post.fecha,
      usuario: widget.post.usuario,
      fotoPerfil: widget.post.fotoPerfil ?? '',
      haDadoLike: widget.post.haDadoLike,
      likesCount: widget.post.likesCount,
      tipoRelacion: widget.post.tipoRelacion,
      guardado: widget.post.guardado,
      idUsuario: widget.post.idUsuario,
    );
  }

  Future<void> _decodeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final data = jsonDecode(payload);
        setState(() {
          userId = int.tryParse(data['sub'].toString());
          print('🔐 ID extraído del token: $userId');
          print(postModel.idUsuario);
        });
      }
    }
  }

  Future<void> _editarPost() async {
    final resultado = await showDialog<List<String>>(
      context: context,
      builder:
          (_) => _EditarPostDialog(
            contenido: postModel.contenido,
            visibilidadActual: postModel.visibilidad,
          ),
    );

    if (resultado != null && resultado.length == 2) {
      final nuevoContenido = resultado[0];
      final nuevaVisibilidad = resultado[1];

      if (nuevoContenido.trim().isNotEmpty &&
          (nuevoContenido != postModel.contenido ||
              nuevaVisibilidad != postModel.visibilidad)) {
        final ok = await Provider.of<PostViewModel>(
          context,
          listen: false,
        ).editarPost(postModel.id, nuevoContenido, nuevaVisibilidad);

        if (ok) {
          setState(() {
            postModel = postModel.copyWith(
              contenido: nuevoContenido,
              visibilidad: nuevaVisibilidad,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contenido actualizado")),
          );
        } else {
          final error =
              Provider.of<PostViewModel>(context, listen: false).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? "Error al actualizar publicación")),
          );
        }
      }
    }
  }

  Future<void> _eliminarPost() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Eliminar publicación?"),
            content: const Text("Esta acción no se puede deshacer."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final ok = await Provider.of<PostViewModel>(
        context,
        listen: false,
      ).eliminarPost(postModel.id);

      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Publicación eliminada")));
      } else {
        final error =
            Provider.of<PostViewModel>(context, listen: false).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? "Error al eliminar publicación")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final likesNotifier = Provider.of<LikesNotifier>(context);
    final likedGlobal = likesNotifier.isLiked(postModel.id);

    final updatedPostModel = postModel.copyWith(
      haDadoLike: likedGlobal,
      likesCount: likesNotifier.getLikesCount(postModel.id),
    );

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Publicación"),
        backgroundColor: const Color(0xFFFFB5B2),
        actions: [
          //Ppermite eliminar o editar la publicación solo si el usuario es el propietario
          if (userId != null && userId == postModel.idUsuario)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  _editarPost();
                } else if (value == 'eliminar') {
                  _eliminarPost();
                }
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Text("Editar publicación"),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Text("Eliminar publicación"),
                    ),
                  ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: PostCard(
            post: updatedPostModel,
            onLikeToggled: (updated) {
              setState(() {
                postModel = updated;
              });

              Provider.of<LikesNotifier>(
                context,
                listen: false,
              ).toggleLike(updated.id, updated.haDadoLike, updated.likesCount);
            },
          ),
        ),
      ),
    );
  }
}

class _EditarPostDialog extends StatefulWidget {
  final String contenido;
  final String visibilidadActual;
  const _EditarPostDialog({
    required this.contenido,
    required this.visibilidadActual,
  });

  @override
  State<_EditarPostDialog> createState() => _EditarPostDialogState();
}

class _EditarPostDialogState extends State<_EditarPostDialog> {
  late TextEditingController _controller;
  late String _visibilidadSeleccionada;

  final List<String> _opcionesVisibilidad = [
    'publico',
    'privado',
    'seguidores',
    'amigos',
  ];

  @override
  void initState() {
    _controller = TextEditingController(text: widget.contenido);
    _visibilidadSeleccionada = widget.visibilidadActual;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar publicación"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _visibilidadSeleccionada,
            items:
                _opcionesVisibilidad
                    .map(
                      (op) => DropdownMenuItem(
                        value: op,
                        child: Text(op[0].toUpperCase() + op.substring(1)),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _visibilidadSeleccionada = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Visibilidad',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(context, [
                _controller.text.trim(),
                _visibilidadSeleccionada,
              ]),
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
