class Comentario {
  final int id;
  final String texto;
  final String autor;
  final DateTime fecha;
  final String? fotoAutor;

  Comentario({
    required this.id,
    required this.texto,
    required this.autor,
    required this.fecha,
    this.fotoAutor,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      texto: json['contenido'],
      autor: json['autor'],
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      fotoAutor: json['foto_autor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'autor': autor,
      'fecha': fecha.toIso8601String(),
      'foto_autor': fotoAutor,
    };
  }
}
