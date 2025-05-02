import '../env.dart';

class GroupModel {
  final String id;
  final String nombre;
  final String? fotoUrl;

  GroupModel({required this.id, required this.nombre, this.fotoUrl});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'].toString(),
      nombre: json['nombre'],
      fotoUrl: json['imagen'] != null ? '$baseURL${json['imagen']}' : null,
    );
  }
}
