class Prenda {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String talla;
  final String color;
  final String tipo;
  final bool solicitable;
  final String? imagenUrl;
  final List<String> categorias;
  final String? estacion;
  final String? emocion;
  final int? usuarioId;

  Prenda({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.talla,
    required this.color,
    required this.tipo,
    required this.solicitable,
    this.imagenUrl,
    required this.categorias,
    this.estacion,
    this.emocion,
    this.usuarioId,
  });

  factory Prenda.fromJson(Map<String, dynamic> json) => Prenda(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    precio: (json['precio'] as num).toDouble(),
    talla: json['talla'],
    color: json['color'],
    tipo: json['tipo'],
    solicitable: json['solicitable'] ?? false,
    imagenUrl: json['imagen_url'],
    categorias: List<String>.from(json['categorias'] ?? []),
    estacion: json['estacion'],
    emocion: json['emocion'],
    usuarioId: json['id_usuario'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'talla': talla,
    'color': color,
    'tipo': tipo,
    'solicitable': solicitable,
    'imagen_url': imagenUrl,
    'categorias': categorias,
    'estacion': estacion,
    'emocion': emocion,
    'id_usuario': usuarioId,
  };
}
