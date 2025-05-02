import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/direct_messages_viewmodel.dart';

class DirectMessagesScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const DirectMessagesScreen({super.key, required this.usuario});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasNewMessages = false;

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        setState(() => _hasNewMessages = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Provider.of<DirectMessagesViewModel>(context, listen: false);
      await vm.obtenerMensajes(widget.usuario['id']);
      _scrollToBottom(animated: false);

      vm.initSocket();
      vm.addListener(() {
        if (!_scrollController.hasClients ||
            _scrollController.position.pixels <
                _scrollController.position.maxScrollExtent - 100) {
          setState(() => _hasNewMessages = true);
        } else {
          _scrollToBottom();
        }
      });
    });
  }

  @override
  void dispose() {
    final vm = Provider.of<DirectMessagesViewModel>(context, listen: false);
    vm.removeListener(_scrollToBottom);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DirectMessagesViewModel>(context);
    final vmMensajes = Provider.of<DirectMessagesViewModel>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.usuario['foto_perfil'] != null)
              CircleAvatar(
                radius: 20, // tamaño del avatar
                backgroundImage: NetworkImage(widget.usuario['foto_perfil']),
                backgroundColor:
                    Colors.grey[300], // color de fondo en caso de carga lenta
              ),
            if (widget.usuario['foto_perfil'] == null)
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.usuario['username'] ?? 'Usuario',
                overflow:
                    TextOverflow.ellipsis, // evita que el texto se corte mal
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_hasNewMessages) GestureDetector(onTap: _scrollToBottom),
          Expanded(
            child:
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: vm.mensajes.length,
                      itemBuilder: (context, index) {
                        final mensaje = vm.mensajes[index];
                        final esMio = mensaje.idEmisor == vm.idUsuarioActual;

                        if (mensaje.publicacion != null) {
                          final post = mensaje.publicacion!;
                          return Align(
                            alignment:
                                esMio
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color:
                                    esMio
                                        ? const Color(0xFFFFB5B2)
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post['imagen_url'] != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        post['imagen_url'],
                                        fit: BoxFit.contain,
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.8,
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      post['contenido'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      "Publicado por ${post['usuario']}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (mensaje.mensaje.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        left: 8.0,
                                        right: 8.0,
                                        bottom: 4.0,
                                      ),
                                      child: Text(
                                        mensaje.mensaje,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Align(
                          alignment:
                              esMio
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  esMio
                                      ? const Color(0xFFFFB5B2)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(mensaje.mensaje),
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
                      hintText: 'Escribe un mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final texto = _controller.text.trim();
                    if (texto.isNotEmpty) {
                      await vmMensajes.enviarMensaje(
                        receptorId: widget.usuario['id'],
                        mensaje: texto,
                      );

                      _controller.clear();
                      _scrollToBottom();
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
