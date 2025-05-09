// messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/messages_viewmodel.dart';
import '../viewmodels/direct_messages_viewmodel.dart';
import 'direct_messages_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesViewModel()..fetchConversaciones(),
      child: Consumer<MessagesViewModel>(
        builder: (context, viewModel, _) {
          return viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: viewModel.usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = viewModel.usuarios[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          usuario.fotoPerfil != null
                              ? NetworkImage(usuario.fotoPerfil!)
                              : null,
                      child:
                          usuario.fotoPerfil == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(usuario.username),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pink.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        usuario.tipo!,
                        style: const TextStyle(color: Colors.pink),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider(
                                create: (_) => DirectMessagesViewModel(),
                                child: DirectMessagesScreen(usuario: usuario),
                              ),
                        ),
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }
}
