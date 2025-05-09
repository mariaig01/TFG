import '../env.dart';

class GroupModel {
  final String id;
  final String nombre;
  final String? fotoUrl;
  final bool? esMiembro;
  final String? creador;

  GroupModel({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    this.esMiembro,
    this.creador,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'].toString(),
      nombre: json['nombre'],
      fotoUrl: json['imagen'] != null ? '$baseURL${json['imagen']}' : null,
      esMiembro: json['es_miembro'] != null ? json['es_miembro'] : false,
    );
  }

  GroupModel copyWith({
    String? id,
    String? nombre,
    String? foto,
    String? creador,
    bool? esMiembro,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fotoUrl: foto ?? this.fotoUrl,
      creador: creador ?? this.creador,
      esMiembro: esMiembro ?? this.esMiembro,
    );
  }
}
