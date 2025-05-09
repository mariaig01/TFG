class UserModel {
  final int id;
  final String username;
  final String? nombre;
  final String? apellido;
  final String? bio;
  final String? fotoPerfil;
  final String? tipo;
  final String? estado;
  final String? estadoSeguidor;

  UserModel({
    required this.id,
    required this.username,
    this.nombre,
    this.apellido,
    this.bio,
    this.fotoPerfil,
    this.tipo,
    this.estado,
    this.estadoSeguidor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      bio: json['bio'],
      fotoPerfil: json['foto_perfil'],
      tipo: json['tipo'],
      estado: json['estado'],
      estadoSeguidor: json['estado_seguidor'],
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? nombre,
    String? apellido,
    String? bio,
    String? fotoPerfil,
    String? tipo,
    String? estado,
    String? estadoSeguidor,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      bio: bio ?? this.bio,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      estadoSeguidor: estadoSeguidor ?? this.estadoSeguidor,
    );
  }
}
