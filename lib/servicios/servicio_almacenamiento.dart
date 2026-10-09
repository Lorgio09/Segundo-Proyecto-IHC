import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as ruta_utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../modelos/modelo_partido.dart';
import '../modelos/modelo_usuario.dart';

/// Servicio de persistencia local.
///
/// - Partidos: base de datos SQLite (tabla `partidos`) en Android / iOS / escritorio.
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
  // ---------------------------------------------------------------------------

  static const String _nombreBaseDatos = 'unisport.db';
  static const String _tablaPartidos = 'partidos';

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

  Future<Database> _abrirBaseDatos() {
    return _conexion ??= () async {
      final ruta =
          _rutaPersonalizada ??
          ruta_utils.join(await getDatabasesPath(), _nombreBaseDatos);
      return openDatabase(
        ruta,
        version: 1,
        onCreate: (db, version) => db.execute('''
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
            PRIMARY KEY (correo_usuario, id)
          )
        '''),
      );
    }();
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

  // ---------------------------------------------------------------------------
  // Partidos (uno por usuario, identificado por su correo)
  // ---------------------------------------------------------------------------

  // 3 - GUARDAR: reemplaza los partidos del usuario dentro de una transacción
  // (cubre crear, editar, eliminar y cambiar de estado).
  Future<void> guardarPartidos(
    String correo,
    List<ModeloPartido> partidos,
  ) async {
    if (kIsWeb) return _guardarPartidosPrefs(correo, partidos);

    final bd = await _abrirBaseDatos();
    await bd.transaction((txn) async {
      await txn.delete(
        _tablaPartidos,
        where: 'correo_usuario = ?',
        whereArgs: [correo],
      );
      final lote = txn.batch();
      for (var i = 0; i < partidos.length; i++) {
        lote.insert(_tablaPartidos, _aFila(correo, partidos[i], i));
      }
      await lote.commit(noResult: true);
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
    }
    await _borrarPartidosPrefs(correo);
  }

  // ---------------------------------------------------------------------------
  // Respaldo con SharedPreferences (web) y origen de la migración a SQLite
  // ---------------------------------------------------------------------------

  String _clavePartidos(String correo) => 'unisport_partidos_$correo';

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
}
