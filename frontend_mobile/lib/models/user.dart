class UserModel {
  final int id;
  final String username;
  final String? nombre;
  final String? apellido;
  final String? bio;
  final String? fotoPerfil;

  UserModel({
    required this.id,
    required this.username,
    this.nombre,
    this.apellido,
    this.bio,
    this.fotoPerfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      bio: json['bio'],
      fotoPerfil: json['foto_perfil'],
    );
  }
}
