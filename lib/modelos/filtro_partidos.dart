import 'modelo_partido.dart';

/// Opciones del filtro por fecha (Issue #9, requisito #6).
enum FiltroFecha {
  cualquiera('Cualquier fecha'),
  hoy('Hoy'),
  proximos7Dias('Próximos 7 días'),
  rango('Rango de fechas');

  final String etiqueta;
  const FiltroFecha(this.etiqueta);
}

/// Búsqueda y filtros que el estudiante aplica en "Explorar partidos".
/// Todos se pueden combinar; un campo vacío o nulo significa "sin filtrar".
class FiltroPartidos {
  /// Lugares que se ofrecen siempre, además de los que ya existen en la base.
  static const List<String> lugaresSugeridos = [
    'Cancha Campus',
    'Coliseo Campus',
    'Estadio Módulo',
  ];

  /// Texto a buscar en el nombre (título) del partido.
  final String texto;
  final String? deporte;
  final FiltroFecha fecha;

  /// Días inicial y final (incluidos) cuando [fecha] es [FiltroFecha.rango].
  final DateTime? desde;
  final DateTime? hasta;
  final String? lugar;

  /// Solo partidos a los que alguien podría unirse (misma regla de #5).
  final bool soloConCupos;

  const FiltroPartidos({
    this.texto = '',
    this.deporte,
    this.fecha = FiltroFecha.cualquiera,
    this.desde,
    this.hasta,
    this.lugar,
    this.soloConCupos = false,
  });

  bool get tieneTexto => texto.trim().isNotEmpty;

  /// ¿Hay algún filtro o búsqueda activa?
  bool get estaActivo =>
      tieneTexto ||
      deporte != null ||
      fecha != FiltroFecha.cualquiera ||
      lugar != null ||
      soloConCupos;

  /// Copia con cambios. Los parámetros `quitar...` permiten volver a "sin filtro".
  FiltroPartidos copiarCon({
    String? texto,
    String? deporte,
    FiltroFecha? fecha,
    DateTime? desde,
    DateTime? hasta,
    String? lugar,
    bool? soloConCupos,
    bool quitarDeporte = false,
    bool quitarLugar = false,
  }) {
    final nuevaFecha = fecha ?? this.fecha;
    final esRango = nuevaFecha == FiltroFecha.rango;
    return FiltroPartidos(
      texto: texto ?? this.texto,
      deporte: quitarDeporte ? null : deporte ?? this.deporte,
      fecha: nuevaFecha,
      desde: esRango ? desde ?? this.desde : null,
      hasta: esRango ? hasta ?? this.hasta : null,
      lugar: quitarLugar ? null : lugar ?? this.lugar,
      soloConCupos: soloConCupos ?? this.soloConCupos,
    );
  }

  /// Intervalo [inicio, fin) de fechas que exige el filtro, tomando [ahora]
  /// como referencia. Es null si no hay filtro de fecha.
  ///
  /// - Hoy: desde las 00:00 de hoy hasta las 00:00 de mañana.
  /// - Próximos 7 días: desde las 00:00 de hoy hasta el final del 7.º día.
  /// - Rango: desde el día inicial hasta el final del día final (incluidos).
  (DateTime, DateTime)? intervaloFechas(DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    switch (fecha) {
      case FiltroFecha.cualquiera:
        return null;
      case FiltroFecha.hoy:
        return (hoy, _sumarDias(hoy, 1));
      case FiltroFecha.proximos7Dias:
        return (hoy, _sumarDias(hoy, 8));
      case FiltroFecha.rango:
        final inicio = desde == null
            ? hoy
            : DateTime(desde!.year, desde!.month, desde!.day);
        final finIncluido = hasta == null
            ? inicio
            : DateTime(hasta!.year, hasta!.month, hasta!.day);
        return (inicio, _sumarDias(finIncluido, 1));
    }
  }

  // Suma días de calendario (evita errores con cambios de horario)
  static DateTime _sumarDias(DateTime dia, int dias) =>
      DateTime(dia.year, dia.month, dia.day + dias);

  /// Traduce el filtro a las condiciones que se envían a la base de datos
  /// (todas se combinan con AND). La aplica el repositorio de Supabase.
  /// Es una función pura para poder probar qué consulta se envía.
  List<CondicionConsulta> condicionesConsulta(DateTime ahora) {
    String instante(DateTime fecha) => fecha.toUtc().toIso8601String();
    final intervalo = intervaloFechas(ahora);
    return [
      if (tieneTexto)
        (
          columna: 'titulo',
          operador: 'ilike',
          valor: '%${_escaparComodines(texto.trim())}%',
        ),
      if (deporte != null)
        (columna: 'disciplina', operador: 'eq', valor: deporte!),
      if (lugar != null)
        (
          columna: 'ubicacion',
          operador: 'ilike',
          valor: '%${_escaparComodines(lugar!)}%',
        ),
      if (intervalo != null) ...[
        (
          columna: 'fecha_inicio',
          operador: 'gte',
          valor: instante(intervalo.$1),
        ),
        (
          columna: 'fecha_inicio',
          operador: 'lt',
          valor: instante(intervalo.$2),
        ),
      ],
      // Misma regla que ModeloPartido.estaDisponible (#5): cupos abiertos,
      // quedan lugares y la fecha todavía no pasó.
      if (soloConCupos) ...[
        (columna: 'estado', operador: 'eq', valor: 'cuposAbiertos'),
        (columna: 'hay_cupos', operador: 'eq', valor: true),
        (columna: 'fecha_inicio', operador: 'gte', valor: instante(ahora)),
      ],
    ];
  }

  // Evita que % y _ escritos por el usuario actúen como comodines en ILIKE
  static String _escaparComodines(String texto) => texto
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  /// La misma regla que la consulta, aplicada en memoria.
  bool coincide(ModeloPartido p, DateTime ahora) {
    if (tieneTexto &&
        !p.titulo.toLowerCase().contains(texto.trim().toLowerCase())) {
      return false;
    }
    if (deporte != null && p.disciplina != deporte) return false;
    if (lugar != null &&
        !p.ubicacion.toLowerCase().contains(lugar!.toLowerCase())) {
      return false;
    }
    final intervalo = intervaloFechas(ahora);
    if (intervalo != null) {
      final inicio = p.fechaInicio;
      if (inicio == null ||
          inicio.isBefore(intervalo.$1) ||
          !inicio.isBefore(intervalo.$2)) {
        return false;
      }
    }
    if (soloConCupos) {
      final inicio = p.fechaInicio;
      final pasado = inicio != null && inicio.isBefore(ahora);
      if (!p.puedeAgregarJugador || pasado) return false;
    }
    return true;
  }
}

/// Una condición de la consulta: columna, operador (eq, ilike, gte, lt) y valor.
typedef CondicionConsulta = ({String columna, String operador, Object valor});
