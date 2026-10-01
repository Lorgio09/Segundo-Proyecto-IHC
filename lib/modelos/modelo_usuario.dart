class ModeloUsuario {
  final String id;
  final String nombre;
  final String correo;
  final String contrasena;
  final String carrera;
  final String deporteFavorito;

  ModeloUsuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    this.carrera = 'Ingeniería',
    this.deporteFavorito = 'Futsal',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'carrera': carrera,
      'deporteFavorito': deporteFavorito,
    };
  }

  factory ModeloUsuario.fromJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      contrasena: json['contrasena'] as String,
      carrera: json['carrera'] as String? ?? 'Ingeniería',
      deporteFavorito: json['deporteFavorito'] as String? ?? 'Futsal',
    );
  }
}
