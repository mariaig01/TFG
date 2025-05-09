class PostModel {
  final int id;
  final String contenido;
  final String visibilidad;
  final String? imagenUrl;
  final String fecha;
  final String usuario;
  final String? fotoPerfil;
  bool haDadoLike;
  int likesCount;
  final String tipoRelacion;
  final bool guardado;
  final int idUsuario;

  PostModel({
    required this.id,
    required this.contenido,
    required this.visibilidad,
    this.imagenUrl,
    required this.fecha,
    required this.usuario,
    this.fotoPerfil,
    this.haDadoLike = false,
    this.likesCount = 0,
    this.tipoRelacion = '',
    this.guardado = false,
    required this.idUsuario,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      contenido: json['contenido'],
      visibilidad: json['visibilidad'],
      imagenUrl: json['imagen_url'] as String?,
      fecha: json['fecha'],
      usuario: json['usuario'],
      fotoPerfil: json['foto_perfil'],
      haDadoLike: json['ha_dado_like'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      tipoRelacion: json['tipo_relacion'] ?? '',
      guardado: json['guardado'] ?? false,
      idUsuario: json['id_usuario'],
    );
  }
  PostModel copyWith({
    bool? haDadoLike,
    int? likesCount,
    bool? guardado,
    String? contenido,
    String? visibilidad,
  }) {
    return PostModel(
      id: id,
      contenido: contenido ?? this.contenido,
      visibilidad: visibilidad ?? this.visibilidad,
      imagenUrl: imagenUrl,
      fecha: fecha,
      usuario: usuario,
      fotoPerfil: fotoPerfil,
      haDadoLike: haDadoLike ?? this.haDadoLike,
      likesCount: likesCount ?? this.likesCount,
      tipoRelacion: tipoRelacion,
      guardado: guardado ?? this.guardado,
      idUsuario: idUsuario,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contenido': contenido,
      'imagen_url': imagenUrl,
      'fecha': fecha,
      'usuario': usuario,
      'foto_perfil': fotoPerfil,
      'ha_dado_like': haDadoLike,
      'likes_count': likesCount,
      'tipo_relacion': tipoRelacion,
      'guardado': guardado,
      'id_usuario': idUsuario,
    };
  }
}
