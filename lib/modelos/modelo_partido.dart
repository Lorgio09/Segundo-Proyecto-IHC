/// Estado de convocatoria de un partido.
enum EstadoPartido {
  cuposAbiertos('Cupos abiertos'),
  equipoCompleto('Equipo completo');

  final String etiqueta;
  const EstadoPartido(this.etiqueta);
}

class ModeloPartido {
  final String id;
  final String titulo;
  final String disciplina;
  final String icono;
  final String ubicacion;
  final String fechaHora;
  final int cuposTotales;
  final int cuposOcupados;
  final String organizadorNombre;
  final bool soyOrganizador;
  final bool estoyUnido;
  final EstadoPartido estado;

  ModeloPartido({
    required this.id,
    required this.titulo,
    required this.disciplina,
    required this.icono,
    required this.ubicacion,
    required this.fechaHora,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.organizadorNombre,
    this.soyOrganizador = false,
    this.estoyUnido = false,
    this.estado = EstadoPartido.cuposAbiertos,
  });

  int get cuposRestantes => cuposTotales - cuposOcupados;
  bool get estaLleno => cuposRestantes <= 0;

  // ---------------------------------------------------------------------------
  // REGLA DE CAMBIO DE ESTADO
  //   Cupos abiertos --(Completar equipo)--> Equipo completo
  //
  //   - Solo el organizador del partido puede completar el equipo.
  //   - Solo se puede completar si el partido está en "Cupos abiertos".
  //   - Al completarlo, los cupos ocupados pasan a ser iguales al total.
  //   - "Equipo completo" es un estado final: no hay vuelta atrás.
  // ---------------------------------------------------------------------------

  /// ¿Se puede ejecutar ahora la acción "Completar equipo"?
  bool get puedeCompletarEquipo =>
      soyOrganizador && estado == EstadoPartido.cuposAbiertos;

  /// Acción "Completar equipo". Devuelve una copia del partido ya completo
  /// (el original no se modifica). Lanza [StateError] si la regla no lo permite.
  ModeloPartido completarEquipo() {
    if (!soyOrganizador) {
      throw StateError('Solo el organizador puede completar el equipo');
    }
    if (estado != EstadoPartido.cuposAbiertos) {
      throw StateError('El equipo de "$titulo" ya está completo');
    }
    return ModeloPartido(
      id: id,
      titulo: titulo,
      disciplina: disciplina,
      icono: icono,
      ubicacion: ubicacion,
      fechaHora: fechaHora,
      cuposTotales: cuposTotales,
      cuposOcupados: cuposTotales,
      organizadorNombre: organizadorNombre,
      soyOrganizador: soyOrganizador,
      estoyUnido: estoyUnido,
      estado: EstadoPartido.equipoCompleto,
    );
  }

  /// Convierte el partido en un Map para poder guardarlo como texto JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'disciplina': disciplina,
    'icono': icono,
    'ubicacion': ubicacion,
    'fechaHora': fechaHora,
    'cuposTotales': cuposTotales,
    'cuposOcupados': cuposOcupados,
    'organizadorNombre': organizadorNombre,
    'soyOrganizador': soyOrganizador,
    'estoyUnido': estoyUnido,
    'estado': estado.name,
  };

  /// Reconstruye un partido a partir de un Map leído del almacenamiento.
  /// Si el estado guardado falta o no se reconoce, queda en "Cupos abiertos".
  factory ModeloPartido.fromJson(Map<String, dynamic> json) => ModeloPartido(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    disciplina: json['disciplina'] as String,
    icono: json['icono'] as String,
    ubicacion: json['ubicacion'] as String,
    fechaHora: json['fechaHora'] as String,
    cuposTotales: json['cuposTotales'] as int,
    cuposOcupados: json['cuposOcupados'] as int,
    organizadorNombre: json['organizadorNombre'] as String,
    soyOrganizador: json['soyOrganizador'] as bool? ?? false,
    estoyUnido: json['estoyUnido'] as bool? ?? false,
    estado:
        EstadoPartido.values.asNameMap()[json['estado'] as String?] ??
        EstadoPartido.cuposAbiertos,
  );
}
