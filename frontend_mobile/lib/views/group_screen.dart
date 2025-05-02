import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/group_viewmodel.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'group_messages_screen.dart';
import '../viewmodels/group_messages_viewmodel.dart';
import 'messages_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final TextEditingController _nombreController = TextEditingController();
  File? _selectedImage;
  int selectedIndex = 0; // 0 = Grupos, 1 = Mensajes

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupViewModel>(context, listen: false).loadGroupsForUser();
    });
  }

  void _mostrarDialogoCrearGrupo() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Crear nuevo grupo"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final status = await Permission.photos.request();
                        if (!status.isGranted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Permiso de galería denegado'),
                            ),
                          );
                          return;
                        }

                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedImage = File(picked.path);
                          });
                          setStateDialog(() {});
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFFFFB5B2),
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                        child:
                            _selectedImage == null
                                ? const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del grupo",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () {
                    Navigator.pop(context);
                    _nombreController.clear();
                    setState(() => _selectedImage = null);
                  },
                ),
                ElevatedButton(
                  child: const Text("Crear"),
                  onPressed: () async {
                    final nombre = _nombreController.text.trim();
                    if (nombre.isNotEmpty) {
                      await Provider.of<GroupViewModel>(
                        context,
                        listen: false,
                      ).crearGrupo(nombre, _selectedImage);
                      Navigator.pop(context);
                      _nombreController.clear();
                      setState(() => _selectedImage = null);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GroupViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grupos y mensajes"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.group_add),
              color: const Color(0xFFFFB5B2),
              tooltip: "Crear grupo",
              onPressed: () {
                setState(() => _selectedImage = null);
                _mostrarDialogoCrearGrupo();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [selectedIndex == 0, selectedIndex == 1],
              onPressed: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(20),
              selectedColor: Colors.white,
              fillColor: const Color(0xFFFFB5B2),
              color: Colors.black87,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Grupos"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Mensajes"),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child:
                selectedIndex == 0
                    ? viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          itemCount: viewModel.groups.length,
                          itemBuilder: (context, index) {
                            final group = viewModel.groups[index];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    group.fotoUrl != null
                                        ? NetworkImage(group.fotoUrl!)
                                        : null,
                                child:
                                    group.fotoUrl == null
                                        ? const Icon(Icons.group)
                                        : null,
                              ),
                              title: Text(group.nombre),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChangeNotifierProvider(
                                          create:
                                              (_) => GroupMessagesViewModel(),
                                          child: Builder(
                                            builder:
                                                (context) =>
                                                    GroupMessagesScreen(
                                                      group: group,
                                                    ),
                                          ),
                                        ),
                                  ),
                                );

                                if (result == 'grupo_abandonado' ||
                                    result == 'grupo_eliminado') {
                                  await viewModel.loadGroupsForUser();
                                  setState(() {});
                                }
                              },
                            );
                          },
                        )
                    : const MessagesScreen(),
          ),
        ],
      ),
    );
  }
}
