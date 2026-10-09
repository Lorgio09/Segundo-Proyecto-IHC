import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/servicios/servicio_almacenamiento.dart';

/// Pruebas de la base de datos SQLite: crear, editar y eliminar partidos
/// y comprobar que los cambios se conservan al volver a leer.
///
/// Ejecutar con:  flutter test test/almacenamiento_sqlite_test.dart
ModeloPartido crearPartido(String id, {String titulo = 'Futsal nocturno'}) {
  return ModeloPartido(
    id: id,
    titulo: titulo,
    disciplina: 'Futsal',
    icono: 'Futsal',
    ubicacion: 'Cancha 2',
    fechaHora: '10/10/2099 · 19:00',
    cuposTotales: 10,
    cuposOcupados: 1,
    organizadorNombre: 'Lorgio',
    soyOrganizador: true,
    estoyUnido: true,
  );
}

void main() {
  const lorgio = 'lorgio@unisport.edu';
  const diego = 'diego@unisport.edu';

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ServicioAlmacenamiento.reiniciarBaseDatos(ruta: inMemoryDatabasePath);
  });

  test('guarda partidos en SQLite y los recupera en el mismo orden', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [crearPartido('b'), crearPartido('a')]);

    final leidos = await ServicioAlmacenamiento().obtenerPartidos(lorgio);

    expect(leidos.map((p) => p.id), ['b', 'a']);
    expect(leidos.first.soyOrganizador, isTrue);
    expect(leidos.first.cuposTotales, 10);
  });

  test('editar un partido conserva los cambios al volver a leer', () async {
    final bd = ServicioAlmacenamiento();
    final original = crearPartido('a');
    await bd.guardarPartidos(lorgio, [original]);

    final editado = original.copyWith(
      titulo: 'Futsal editado',
      ubicacion: 'Cancha 5',
      cuposTotales: 12,
    );
    await bd.guardarPartidos(lorgio, [editado]);

    final leido = (await bd.obtenerPartidos(lorgio)).single;
    expect(leido.titulo, 'Futsal editado');
    expect(leido.ubicacion, 'Cancha 5');
    expect(leido.cuposTotales, 12);
  });

  test('eliminar un partido lo quita de la base de datos', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [crearPartido('a'), crearPartido('b')]);

    await bd.guardarPartidos(lorgio, [crearPartido('b')]);

    final leidos = await bd.obtenerPartidos(lorgio);
    expect(leidos.map((p) => p.id), ['b']);
  });

  test('cada usuario solo ve sus propios partidos', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [crearPartido('l1')]);
    await bd.guardarPartidos(diego, [crearPartido('d1'), crearPartido('d2')]);

    expect((await bd.obtenerPartidos(lorgio)).map((p) => p.id), ['l1']);
    expect((await bd.obtenerPartidos(diego)).map((p) => p.id), ['d1', 'd2']);
  });

  test('migra a SQLite los partidos que estaban en SharedPreferences', () async {
    final antiguo = jsonEncode(crearPartido('viejo').toJson());
    SharedPreferences.setMockInitialValues({
      'unisport_partidos_$lorgio': [antiguo],
    });
    final bd = ServicioAlmacenamiento();

    final primera = await bd.obtenerPartidos(lorgio);
    expect(primera.single.id, 'viejo');

    // Ya quedó en SQLite: se puede borrar y no reaparece desde SharedPreferences
    await bd.guardarPartidos(lorgio, []);
    expect(await bd.obtenerPartidos(lorgio), isEmpty);
  });
}
