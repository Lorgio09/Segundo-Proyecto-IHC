import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as ruta_utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../modelos/modelo_partido.dart';
import '../modelos/modelo_usuario.dart';

/// Servicio de persistencia local.
///
/// - Partidos e inscripciones: base de datos SQLite (tablas `partidos` e
///   `inscripciones`) en Android / iOS / escritorio.
///   En navegador web, donde `sqflite` no existe, se usa SharedPreferences como
///   respaldo para poder seguir desarrollando en Chrome.
/// - Sesión y usuarios registrados: SharedPreferences.
class ServicioAlmacenamiento {
  static const String _claveUsuario = 'unisport_usuario_sesion';
  static const String _claveUsuariosRegistrados =
      'unisport_usuarios_registrados';

  // ---------------------------------------------------------------------------
  // Sesión y usuarios
  // ---------------------------------------------------------------------------

  // Guardar usuario con sesión activa
  Future<void> guardarSesion(ModeloUsuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUsuario, jsonEncode(usuario.toJson()));
  }

  // Obtener usuario con sesión activa
  Future<ModeloUsuario?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString(_claveUsuario);
    if (usuarioJson == null) return null;
    try {
      final mapa = jsonDecode(usuarioJson) as Map<String, dynamic>;
      return ModeloUsuario.fromJson(mapa);
    } catch (_) {
      return null;
    }
  }

  // Borrar sesión activa (Logout)
  Future<void> borrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUsuario);
  }

  // Guardar lista de usuarios registrados
  Future<void> guardarUsuarios(List<ModeloUsuario> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = usuarios.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_claveUsuariosRegistrados, listaJson);
  }

  // Obtener lista de usuarios registrados
  Future<List<ModeloUsuario>> obtenerUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(_claveUsuariosRegistrados);
    if (listaJson == null || listaJson.isEmpty) return [];

    return listaJson.map((str) {
      final mapa = jsonDecode(str) as Map<String, dynamic>;
      return ModeloUsuario.fromJson(mapa);
    }).toList();
  }


  // ---------------------------------------------------------------------------
  // Base de datos SQLite
  //   partidos:      un partido por fila, guardado bajo el correo de su organizador
  //   inscripciones: qué estudiante se unió a qué partido (Issue #3)
  // ---------------------------------------------------------------------------

  static const String _nombreBaseDatos = 'unisport.db';
  static const String _tablaPartidos = 'partidos';
  static const String _tablaInscripciones = 'inscripciones';

  // Una sola conexión compartida por todas las instancias del servicio
  static Future<Database>? _conexion;
  static String? _rutaPersonalizada;

  /// Cierra la conexión actual. Solo para pruebas: permite abrir una base
  /// distinta (por ejemplo `inMemoryDatabasePath`) en cada prueba.
  @visibleForTesting
  static Future<void> reiniciarBaseDatos({String? ruta}) async {
    final actual = _conexion;
    _conexion = null;
    _rutaPersonalizada = ruta;
    if (actual != null) await (await actual).close();
  }

  static Future<void> _crearTablaInscripciones(DatabaseExecutor db) =>
      db.execute('''
        CREATE TABLE $_tablaInscripciones (
          correo_organizador TEXT NOT NULL,
          partido_id         TEXT NOT NULL,
          correo_jugador     TEXT NOT NULL,
          nombre_jugador     TEXT NOT NULL DEFAULT '',
          PRIMARY KEY (correo_organizador, partido_id, correo_jugador)
        )
      ''');

  Future<Database> _abrirBaseDatos() {
    return _conexion ??= () async {
      final ruta =
          _rutaPersonalizada ??
          ruta_utils.join(await getDatabasesPath(), _nombreBaseDatos);
      return openDatabase(
        ruta,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tablaPartidos (
              correo_usuario    TEXT    NOT NULL,
              id                TEXT    NOT NULL,
              titulo            TEXT    NOT NULL,
              disciplina        TEXT    NOT NULL,
              icono             TEXT    NOT NULL,
              ubicacion         TEXT    NOT NULL,
              fecha_hora        TEXT    NOT NULL,
              cupos_totales     INTEGER NOT NULL,
              cupos_ocupados    INTEGER NOT NULL,
              organizador_nombre TEXT   NOT NULL,
              soy_organizador   INTEGER NOT NULL,
              estoy_unido       INTEGER NOT NULL,
              estado            TEXT    NOT NULL,
              orden             INTEGER NOT NULL,
              fecha_inicio      INTEGER,
              PRIMARY KEY (correo_usuario, id)
            )
          ''');
          await _crearTablaInscripciones(db);
        },
        // Teléfonos con una versión anterior reciben solo lo que les falta
        onUpgrade: (db, anterior, nueva) async {
          if (anterior < 2) await _crearTablaInscripciones(db);
          if (anterior == 2) {
            await db.execute(
              "ALTER TABLE $_tablaInscripciones "
              "ADD COLUMN nombre_jugador TEXT NOT NULL DEFAULT ''",
            );
          }
          if (anterior < 3) {
            await db.execute(
              'ALTER TABLE $_tablaPartidos ADD COLUMN fecha_inicio INTEGER',
            );
            await _completarFechasInicio(db);
          }
        },
      );
    }();
  }

  /// Convierte a fecha real (columna fecha_inicio) el texto de fecha de los
  /// partidos guardados antes de la versión 3 de la base de datos.
  static Future<void> _completarFechasInicio(DatabaseExecutor db) async {
    final filas = await db.query(
      _tablaPartidos,
      columns: ['correo_usuario', 'id', 'fecha_hora'],
    );
    for (final f in filas) {
      final fecha = ModeloPartido.interpretarFechaHora(f['fecha_hora'] as String);
      await db.update(
        _tablaPartidos,
        {'fecha_inicio': fecha?.millisecondsSinceEpoch},
        where: 'correo_usuario = ? AND id = ?',
        whereArgs: [f['correo_usuario'], f['id']],
      );
    }
  }

  Map<String, Object?> _aFila(String correo, ModeloPartido p, int orden) => {
    'correo_usuario': correo,
    'id': p.id,
    'titulo': p.titulo,
    'disciplina': p.disciplina,
    'icono': p.icono,
    'ubicacion': p.ubicacion,
    'fecha_hora': p.fechaHora,
    'cupos_totales': p.cuposTotales,
    'cupos_ocupados': p.cuposOcupados,
    'organizador_nombre': p.organizadorNombre,
    'soy_organizador': p.soyOrganizador ? 1 : 0,
    'estoy_unido': p.estoyUnido ? 1 : 0,
    'estado': p.estado.name,
    'orden': orden,
    'fecha_inicio': p.fechaInicio?.millisecondsSinceEpoch,
  };

  ModeloPartido _desdeFila(Map<String, Object?> f) => ModeloPartido(
    id: f['id'] as String,
    titulo: f['titulo'] as String,
    disciplina: f['disciplina'] as String,
    icono: f['icono'] as String,
    ubicacion: f['ubicacion'] as String,
    fechaHora: f['fecha_hora'] as String,
    cuposTotales: f['cupos_totales'] as int,
    cuposOcupados: f['cupos_ocupados'] as int,
    organizadorNombre: f['organizador_nombre'] as String,
    soyOrganizador: (f['soy_organizador'] as int) == 1,
    estoyUnido: (f['estoy_unido'] as int) == 1,
    estado:
        EstadoPartido.values.asNameMap()[f['estado'] as String] ??
        EstadoPartido.cuposAbiertos,
  );

  /// El mismo partido visto por otro estudiante (no organizador).
  ModeloPartido _vistoPorJugador(
    ModeloPartido p, {
    required String correoOrganizador,
    required String correoJugador,
    required bool inscrito,
  }) {
    final esOrganizador = correoOrganizador == correoJugador;
    return p.copyWith(
      soyOrganizador: esOrganizador,
      estoyUnido: esOrganizador || inscrito,
    );
  }

  // ---------------------------------------------------------------------------
  // Partidos que organiza cada usuario
  // ---------------------------------------------------------------------------

  // 3 - GUARDAR: reemplaza los partidos que organiza el usuario dentro de una
  // transacción (cubre crear, editar, eliminar y cambiar de estado).
  // Los partidos de otros a los que se unió no se guardan aquí, sino como
  // inscripciones.
  Future<void> guardarPartidos(
    String correo,
    List<ModeloPartido> partidos,
  ) async {
    final propios = partidos.where((p) => p.soyOrganizador).toList();
    if (kIsWeb) return _guardarPartidosPrefs(correo, propios);

    final bd = await _abrirBaseDatos();
    await bd.transaction((txn) async {
      await txn.delete(
        _tablaPartidos,
        where: 'correo_usuario = ?',
        whereArgs: [correo],
      );
      final lote = txn.batch();
      for (var i = 0; i < propios.length; i++) {
        lote.insert(_tablaPartidos, _aFila(correo, propios[i], i));
      }
      await lote.commit(noResult: true);

      // Si el organizador eliminó un partido, se borran sus inscripciones
      final ids = propios.map((p) => p.id).toList();
      await txn.delete(
        _tablaInscripciones,
        where: ids.isEmpty
            ? 'correo_organizador = ?'
            : 'correo_organizador = ? AND partido_id NOT IN '
                  '(${List.filled(ids.length, '?').join(', ')})',
        whereArgs: [correo, ...ids],
      );
    });
  }

  // 5 - RECUPERAR
  Future<List<ModeloPartido>> obtenerPartidos(String correo) async {
    if (kIsWeb) return _obtenerPartidosPrefs(correo);

    final bd = await _abrirBaseDatos();
    final filas = await bd.query(
      _tablaPartidos,
      where: 'correo_usuario = ?',
      whereArgs: [correo],
      orderBy: 'orden ASC',
    );
    if (filas.isNotEmpty) return filas.map(_desdeFila).toList();

    // Primera vez con SQLite: se pasan a la base de datos los partidos que
    // este usuario tenía guardados antes en SharedPreferences.
    final anteriores = await _obtenerPartidosPrefs(correo);
    if (anteriores.isEmpty) return [];
    await guardarPartidos(correo, anteriores);
    await _borrarPartidosPrefs(correo);
    return anteriores;
  }

  Future<void> borrarPartidos(String correo) async {
    if (!kIsWeb) {
      final bd = await _abrirBaseDatos();
      await bd.delete(
        _tablaPartidos,
        where: 'correo_usuario = ?',
        whereArgs: [correo],
      );
      await bd.delete(
        _tablaInscripciones,
        where: 'correo_organizador = ?',
        whereArgs: [correo],
      );
    }
    await _borrarPartidosPrefs(correo);
  }

  // ---------------------------------------------------------------------------
  // Explorar y unirse a partidos de otros estudiantes (Issue #3)
  // ---------------------------------------------------------------------------

  /// Partidos organizados por otros estudiantes, vistos por [correoJugador]:
  /// cada uno indica si ese estudiante ya está inscrito.
  Future<List<PartidoPublicado>> obtenerPartidosParaExplorar(
    String correoJugador,
  ) async {
    if (kIsWeb) return _explorarPrefs(correoJugador);

    final bd = await _abrirBaseDatos();
    final filas = await bd.query(
      _tablaPartidos,
      where: 'correo_usuario <> ?',
      whereArgs: [correoJugador],
      orderBy: 'correo_usuario ASC, orden ASC',
    );
    final inscripciones = await bd.query(
      _tablaInscripciones,
      where: 'correo_jugador = ?',
      whereArgs: [correoJugador],
    );
    final inscritos = {
      for (final i in inscripciones)
        '${i['correo_organizador']}|${i['partido_id']}',
    };

    return [
      for (final f in filas)
        (
          correoOrganizador: f['correo_usuario'] as String,
          partido: _vistoPorJugador(
            _desdeFila(f),
            correoOrganizador: f['correo_usuario'] as String,
            correoJugador: correoJugador,
            inscrito: inscritos.contains('${f['correo_usuario']}|${f['id']}'),
          ),
        ),
    ];
  }

  /// Partidos de otros a los que [correoJugador] se unió (para "Como jugador").
  Future<List<ModeloPartido>> obtenerPartidosUnidos(String correoJugador) async {
    final todos = await obtenerPartidosParaExplorar(correoJugador);
    return [
      for (final item in todos)
        if (item.partido.estoyUnido) item.partido,
    ];
  }

  /// Une a [correoJugador] al partido [partidoId] de [correoOrganizador].
  ///
  /// Aplica la regla del modelo ([ModeloPartido.unirse]) sobre el dato guardado
  /// y, si se acepta, actualiza los cupos y registra la inscripción en una sola
  /// transacción. Si se rechaza, lanza [StateError] con el motivo y no guarda nada.
  Future<ModeloPartido> unirseAPartido({
    required String correoJugador,
    required String nombreJugador,
    required String correoOrganizador,
    required String partidoId,
  }) async {
    if (kIsWeb) {
      return _unirsePrefs(
        correoJugador,
        nombreJugador,
        correoOrganizador,
        partidoId,
      );
    }

    final bd = await _abrirBaseDatos();
    return bd.transaction((txn) async {
      final filas = await txn.query(
        _tablaPartidos,
        where: 'correo_usuario = ? AND id = ?',
        whereArgs: [correoOrganizador, partidoId],
      );
      if (filas.isEmpty) throw StateError('Este partido ya no existe.');

      final yaInscrito = (await txn.query(
        _tablaInscripciones,
        where: 'correo_organizador = ? AND partido_id = ? AND correo_jugador = ?',
        whereArgs: [correoOrganizador, partidoId, correoJugador],
      )).isNotEmpty;

      final partido = _vistoPorJugador(
        _desdeFila(filas.first),
        correoOrganizador: correoOrganizador,
        correoJugador: correoJugador,
        inscrito: yaInscrito,
      );

      final unido = partido.unirse(); // lanza StateError con el motivo

      await txn.update(
        _tablaPartidos,
        {'cupos_ocupados': unido.cuposOcupados, 'estado': unido.estado.name},
        where: 'correo_usuario = ? AND id = ?',
        whereArgs: [correoOrganizador, partidoId],
      );
      await txn.insert(_tablaInscripciones, {
        'correo_organizador': correoOrganizador,
        'partido_id': partidoId,
        'correo_jugador': correoJugador,
        'nombre_jugador': nombreJugador,
      });
      return unido;
    });
  }

  /// Quién se unió a cada partido de [correoOrganizador] (Issue #8).
  /// Devuelve, por id de partido, los nombres en el orden en que se unieron.
  Future<Map<String, List<String>>> obtenerJugadoresInscritos(
    String correoOrganizador,
  ) async {
    if (kIsWeb) return _jugadoresInscritosPrefs(correoOrganizador);

    final bd = await _abrirBaseDatos();
    final filas = await bd.query(
      _tablaInscripciones,
      columns: ['partido_id', 'correo_jugador', 'nombre_jugador'],
      where: 'correo_organizador = ?',
      whereArgs: [correoOrganizador],
      orderBy: 'rowid ASC',
    );
    final resultado = <String, List<String>>{};
    for (final f in filas) {
      final nombre = f['nombre_jugador'] as String;
      resultado
          .putIfAbsent(f['partido_id'] as String, () => [])
          .add(nombre.isEmpty ? f['correo_jugador'] as String : nombre);
    }
    return resultado;
  }

  // ---------------------------------------------------------------------------
  // Respaldo con SharedPreferences (web) y origen de la migración a SQLite
  // ---------------------------------------------------------------------------

  static const String _prefijoPartidos = 'unisport_partidos_';
  static const String _claveInscripciones = 'unisport_inscripciones';

  String _clavePartidos(String correo) => '$_prefijoPartidos$correo';

  Future<void> _guardarPartidosPrefs(
    String correo,
    List<ModeloPartido> partidos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = partidos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_clavePartidos(correo), listaJson);
  }

  Future<List<ModeloPartido>> _obtenerPartidosPrefs(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(_clavePartidos(correo));
    if (listaJson == null || listaJson.isEmpty) return [];
    try {
      return listaJson
          .map(
            (s) =>
                ModeloPartido.fromJson(jsonDecode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _borrarPartidosPrefs(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clavePartidos(correo));
  }

  /// Inscripciones guardadas en el navegador: [organizador, partido, jugador, nombre].
  List<List<String>> _inscripcionesPrefs(SharedPreferences prefs) => [
    for (final texto in prefs.getStringList(_claveInscripciones) ?? const [])
      (jsonDecode(texto) as List).cast<String>(),
  ];

  bool _estaInscritoPrefs(
    List<List<String>> inscripciones,
    String organizador,
    String id,
    String jugador,
  ) => inscripciones.any(
    (i) => i[0] == organizador && i[1] == id && i[2] == jugador,
  );

  Future<Map<String, List<String>>> _jugadoresInscritosPrefs(
    String correoOrganizador,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final resultado = <String, List<String>>{};
    for (final i in _inscripcionesPrefs(prefs)) {
      if (i[0] != correoOrganizador) continue;
      final nombre = i.length > 3 && i[3].isNotEmpty ? i[3] : i[2];
      resultado.putIfAbsent(i[1], () => []).add(nombre);
    }
    return resultado;
  }

  Future<List<PartidoPublicado>> _explorarPrefs(String correoJugador) async {
    final prefs = await SharedPreferences.getInstance();
    final inscripciones = _inscripcionesPrefs(prefs);
    final resultado = <PartidoPublicado>[];
    final claves =
        prefs.getKeys().where((k) => k.startsWith(_prefijoPartidos)).toList()
          ..sort();
    for (final clave in claves) {
      final organizador = clave.substring(_prefijoPartidos.length);
      if (organizador == correoJugador) continue;
      for (final p in await _obtenerPartidosPrefs(organizador)) {
        resultado.add((
          correoOrganizador: organizador,
          partido: _vistoPorJugador(
            p,
            correoOrganizador: organizador,
            correoJugador: correoJugador,
            inscrito: _estaInscritoPrefs(
              inscripciones,
              organizador,
              p.id,
              correoJugador,
            ),
          ),
        ));
      }
    }
    return resultado;
  }

  Future<ModeloPartido> _unirsePrefs(
    String correoJugador,
    String nombreJugador,
    String correoOrganizador,
    String partidoId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final inscripciones = _inscripcionesPrefs(prefs);

    final partidos = await _obtenerPartidosPrefs(correoOrganizador);
    final indice = partidos.indexWhere((p) => p.id == partidoId);
    if (indice < 0) throw StateError('Este partido ya no existe.');

    final unido = _vistoPorJugador(
      partidos[indice],
      correoOrganizador: correoOrganizador,
      correoJugador: correoJugador,
      inscrito: _estaInscritoPrefs(
        inscripciones,
        correoOrganizador,
        partidoId,
        correoJugador,
      ),
    ).unirse(); // lanza StateError con el motivo

    partidos[indice] = partidos[indice].copyWith(
      cuposOcupados: unido.cuposOcupados,
      estado: unido.estado,
    );
    await _guardarPartidosPrefs(correoOrganizador, partidos);
    await prefs.setStringList(_claveInscripciones, [
      ...prefs.getStringList(_claveInscripciones) ?? const [],
      jsonEncode([correoOrganizador, partidoId, correoJugador, nombreJugador]),
    ]);
    return unido;
  }
}

/// Un partido de otro estudiante junto con el correo de quien lo organiza.
typedef PartidoPublicado = ({String correoOrganizador, ModeloPartido partido});
