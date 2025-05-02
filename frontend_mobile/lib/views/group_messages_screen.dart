import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/group_messages_viewmodel.dart';

class GroupMessagesScreen extends StatefulWidget {
  final GroupModel group;

  const GroupMessagesScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupMessagesScreen> createState() => _GroupMessagesScreenState();
}

class _GroupMessagesScreenState extends State<GroupMessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Provider.of<GroupMessagesViewModel>(context, listen: false);
      await vm.loadMessages(widget.group.id);
      _scrollToBottom(animated: false);
      vm.initSocketGrupo(int.parse(widget.group.id));
    });
  }

  void _scrollToBottom({bool animated = true}) {
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
    }
  }

  void _mostrarInfoGrupo() {
    final vm = Provider.of<GroupMessagesViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Información del grupo"),
            content: FutureBuilder(
              future: Provider.of<GroupMessagesViewModel>(
                context,
                listen: false,
              ).loadGroupInfo(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final info = snapshot.data as Map<String, dynamic>;
                print(widget.group.id);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.group.fotoUrl != null)
                      ClipOval(
                        child: Image.network(
                          widget.group.fotoUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),

                    Text("👤 Creador: ${info['creador']}"),
                    Text("👥 Miembros: ${info['num_miembros']}"),
                    const SizedBox(height: 20),

                    if (info['id_creador'] == vm.idUsuarioActual)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar grupo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            247,
                            70,
                            123,
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text("¿Eliminar grupo?"),
                                  content: const Text(
                                    "Esta acción eliminará el grupo permanentemente.",
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancelar"),
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Eliminar",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                          );

                          if (confirmed == true) {
                            await Provider.of<GroupViewModel>(
                              context,
                              listen: false,
                            ).eliminarGrupo(int.parse(widget.group.id));

                            Navigator.pop(context); // Cierra info
                            Navigator.pop(
                              context,
                              'grupo_eliminado',
                            ); // Sale de la pantalla
                          }
                        },
                      ),
                    TextButton(
                      child: const Text("Abandonar grupo"),
                      onPressed: () async {
                        await Provider.of<GroupViewModel>(
                          context,
                          listen: false,
                        ).abandonarGrupo(int.parse(widget.group.id));
                        Navigator.pop(context); // Cierra info
                        Navigator.pop(
                          context,
                          'grupo_abandonado',
                        ); // Sale de la pantalla
                      },
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.group.fotoUrl != null)
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(widget.group.fotoUrl!),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.group.nombre, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarInfoGrupo,
          ),
        ],
      ),
      body: Consumer<GroupMessagesViewModel>(
        builder: (context, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!vm.isLoading && _scrollController.hasClients) {
              _scrollToBottom();
            }
          });

          return Column(
            children: [
              Expanded(
                child:
                    vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: vm.messages.length,
                          itemBuilder: (context, index) {
                            final msg = vm.messages[index];
                            final esMio = msg.idUsuario == vm.idUsuarioActual;

                            return Align(
                              alignment:
                                  esMio
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      esMio
                                          ? const Color(0xFFFFB5B2)
                                          : Colors.grey[200],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      esMio
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    if (!esMio)
                                      Text(
                                        msg.autor,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (msg.publicacion != null)
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (msg.publicacion!['imagen_url'] !=
                                                null)
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                                child: Image.network(
                                                  msg.publicacion!['imagen_url'],
                                                  fit: BoxFit.contain,
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.8,
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                msg.publicacion!['contenido'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: Text(
                                                "Publicado por ${msg.publicacion!['usuario']}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            if (msg.mensaje.trim().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                  right: 8.0,
                                                  bottom: 8.0,
                                                  top: 4.0,
                                                ),
                                                child: Text(
                                                  msg.mensaje,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    else
                                      Text(msg.mensaje),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        final texto = _messageController.text.trim();
                        if (texto.isNotEmpty) {
                          await Provider.of<GroupViewModel>(
                            context,
                            listen: false,
                          ).enviarMensajeGrupo(
                            grupoId: int.parse(widget.group.id),
                            mensaje: texto,
                          );
                          _messageController.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
