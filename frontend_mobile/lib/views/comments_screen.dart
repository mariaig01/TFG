import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/comments_viewmodel.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vm = Provider.of<CommentViewModel>(context, listen: false);
      vm.fetchComentarios(widget.postId);
      vm.initSocketComments(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CommentViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comentarios"),
        backgroundColor: const Color(0xFFFFB5B2),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.comentarios.isEmpty
                    ? const Center(child: Text("Sin comentarios aún"))
                    : ListView.builder(
                      itemCount: vm.comentarios.length,
                      itemBuilder: (context, index) {
                        final c = vm.comentarios[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                c.fotoAutor != null
                                    ? NetworkImage(c.fotoAutor!)
                                    : const AssetImage(
                                          'assets/default_avatar.png',
                                        )
                                        as ImageProvider,
                          ),
                          title: Text(c.autor),
                          subtitle: Text(c.texto),
                          trailing: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(c.fecha),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFB5B2)),
                  onPressed: () async {
                    final texto = _controller.text.trim();
                    if (texto.isNotEmpty) {
                      await vm.enviarComentario(widget.postId, texto);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
