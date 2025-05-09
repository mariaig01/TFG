import 'post.dart';

class DirectMessage {
  final int id;
  final int idEmisor;
  final int idReceptor;
  final String? mensaje;
  final DateTime? fecha;
  final PostModel? publicacion;

  DirectMessage({
    required this.id,
    required this.idEmisor,
    required this.idReceptor,
    this.mensaje,
    this.fecha,
    this.publicacion,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'],
      idEmisor: json['id_emisor'],
      idReceptor: json['id_receptor'],
      mensaje: json['mensaje'],
      fecha: DateTime.parse(json['fecha_envio']),
      publicacion:
          json['publicacion'] != null
              ? PostModel.fromJson(json['publicacion'])
              : null,
    );
  }
}
