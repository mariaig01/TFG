import 'post.dart';

class GroupMessage {
  final int id;
  final int idGrupo;
  final int idUsuario;
  final String mensaje;
  final DateTime fechaEnvio;
  final String autor;
  final PostModel? publicacion;

  GroupMessage({
    required this.id,
    required this.idGrupo,
    required this.idUsuario,
    required this.mensaje,
    required this.fechaEnvio,
    required this.autor,
    this.publicacion,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      idGrupo: json['id_grupo'],
      idUsuario: json['id_usuario'],
      mensaje: json['mensaje'],
      fechaEnvio: DateTime.parse(json['fecha_envio']),
      autor: json['autor'] ?? 'Anónimo',
      publicacion:
          json['publicacion'] != null
              ? PostModel.fromJson(json['publicacion'])
              : null,
    );
  }
}
