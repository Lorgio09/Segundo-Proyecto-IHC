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

  // ---------------------------------------------------------------------------
  // REGLA DE RESTRICCIÓN (UNISPORT)
  //   "Un equipo completo no permite agregar más jugadores"
  //   Cuando una acción esté bloqueada, la interfaz debe explicar claramente el motivo.
  // ---------------------------------------------------------------------------

  /// ¿Se puede agregar un jugador a este partido ahora mismo?
  bool get puedeAgregarJugador =>
      estado == EstadoPartido.cuposAbiertos && !estaLleno;

  /// Motivo claro por el cual está bloqueada la acción de agregar jugadores.
  /// Si la acción está permitida, devuelve null.
  String? get motivoBloqueoAgregarJugador {
    if (estado == EstadoPartido.equipoCompleto) {
      return 'Convocatoria cerrada: el equipo ya está completo.';
    }
    if (estaLleno) {
      return 'Cupos agotados: se alcanzó el límite máximo de jugadores.';
    }
    return null;
  }

  /// Acción de agregar un jugador (unirse al equipo).
  /// Devuelve una copia inmutable del partido con cupos actualizados.
  /// Lanza [StateError] si la restricción de estado no lo permite.
  ModeloPartido agregarJugador({bool marcarComoUnido = true}) {
    if (!puedeAgregarJugador) {
      throw StateError(
        motivoBloqueoAgregarJugador ??
            'No se pueden agregar más jugadores a este equipo',
      );
    }
    final nuevosOcupados = cuposOcupados + 1;
    final seCompleto = nuevosOcupados >= cuposTotales;

    return copyWith(
      cuposOcupados: nuevosOcupados,
      estoyUnido: estoyUnido || marcarComoUnido,
      estado: seCompleto ? EstadoPartido.equipoCompleto : estado,
    );
  }

  // ---------------------------------------------------------------------------
  // REGLA DE UNIÓN AL PARTIDO (Issue #2, historia #1)
  //   Un estudiante puede unirse si:
  //   - no forma parte del equipo (el organizador ya cuenta como jugador), y
  //   - el partido tiene cupos abiertos.
  //   Al ocupar el último cupo, el partido pasa a "Equipo completo".
  // ---------------------------------------------------------------------------

  /// ¿Puede el usuario actual unirse a este partido?
  bool get puedeUnirse => motivoRechazoUnirse == null;

  /// Motivo por el que se rechaza la unión, o null si está permitida.
  String? get motivoRechazoUnirse {
    if (soyOrganizador || estoyUnido) {
      return 'Ya formas parte de este equipo.';
    }
    return motivoBloqueoAgregarJugador;
  }

  /// Acción "Unirme al equipo". Devuelve una copia con un cupo más ocupado y
  /// el usuario marcado como unido. Lanza [StateError] con el motivo si la
  /// regla lo rechaza; en ese caso el partido no cambia.
  ModeloPartido unirse() {
    final motivo = motivoRechazoUnirse;
    if (motivo != null) throw StateError(motivo);
    return agregarJugador(marcarComoUnido: true);
  }

  /// Genera una copia inmutable con campos modificados para el flujo de edición.
  ModeloPartido copyWith({
    String? id,
    String? titulo,
    String? disciplina,
    String? icono,
    String? ubicacion,
    String? fechaHora,
    int? cuposTotales,
    int? cuposOcupados,
    String? organizadorNombre,
    bool? soyOrganizador,
    bool? estoyUnido,
    EstadoPartido? estado,
  }) {
    return ModeloPartido(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      disciplina: disciplina ?? this.disciplina,
      icono: icono ?? this.icono,
      ubicacion: ubicacion ?? this.ubicacion,
      fechaHora: fechaHora ?? this.fechaHora,
      cuposTotales: cuposTotales ?? this.cuposTotales,
      cuposOcupados: cuposOcupados ?? this.cuposOcupados,
      organizadorNombre: organizadorNombre ?? this.organizadorNombre,
      soyOrganizador: soyOrganizador ?? this.soyOrganizador,
      estoyUnido: estoyUnido ?? this.estoyUnido,
      estado: estado ?? this.estado,
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
