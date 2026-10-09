import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/servicios/servicio_almacenamiento.dart';

/// Pruebas de persistencia de la unión a partidos (Issue #3, historia #1):
/// explorar partidos de otros, unirse y conservar la unión al recargar.
///
/// Ejecutar con:  flutter test test/union_almacenamiento_test.dart
const lorgio = 'lorgio@unisport.edu';
const diego = 'diego@unisport.edu';
const ana = 'ana@unisport.edu';

ModeloPartido partidoDeLorgio({
  String id = 'p-1',
  int cuposTotales = 10,
  int cuposOcupados = 1,
  String fechaHora = '10/10/2099 · 19:00',
}) {
  return ModeloPartido(
    id: id,
    titulo: 'Futsal nocturno',
    disciplina: 'Futsal',
    icono: 'Futsal',
    ubicacion: 'Cancha 2',
    fechaHora: fechaHora,
    cuposTotales: cuposTotales,
    cuposOcupados: cuposOcupados,
    organizadorNombre: 'Lorgio',
    soyOrganizador: true,
    estoyUnido: true,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ServicioAlmacenamiento.reiniciarBaseDatos(ruta: inMemoryDatabasePath);
  });

  test('explorar muestra los partidos de otros y no los propios', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [partidoDeLorgio()]);

    final paraDiego = await bd.obtenerPartidosParaExplorar(diego);
    final paraLorgio = await bd.obtenerPartidosParaExplorar(lorgio);

    expect(paraDiego.single.correoOrganizador, lorgio);
    expect(paraDiego.single.partido.soyOrganizador, isFalse);
    expect(paraDiego.single.partido.puedeUnirse, isTrue);
    expect(paraLorgio, isEmpty);
  });

  test('la unión se guarda y permanece al recargar (criterio 5)', () async {
    await ServicioAlmacenamiento().guardarPartidos(lorgio, [partidoDeLorgio()]);

    final unido = await ServicioAlmacenamiento().unirseAPartido(
      correoJugador: diego,
      nombreJugador: 'Diego',
      correoOrganizador: lorgio,
      partidoId: 'p-1',
    );
    expect(unido.cuposOcupados, 2);
    expect(unido.estoyUnido, isTrue);

    // Servicio nuevo = volver a abrir la app
    final recargado = ServicioAlmacenamiento();
    final unidosDeDiego = await recargado.obtenerPartidosUnidos(diego);
    final propiosDeLorgio = await recargado.obtenerPartidos(lorgio);

    expect(unidosDeDiego.single.id, 'p-1');
    expect(unidosDeDiego.single.estoyUnido, isTrue);
    expect(propiosDeLorgio.single.cuposOcupados, 2);
  });

  test('unirse dos veces se rechaza y los cupos no cambian (criterio 4)', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [partidoDeLorgio()]);
    await bd.unirseAPartido(
      correoJugador: diego,
      nombreJugador: 'Diego',
      correoOrganizador: lorgio,
      partidoId: 'p-1',
    );

    await expectLater(
      bd.unirseAPartido(
        correoJugador: diego,
        nombreJugador: 'Diego',
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'motivo',
          'Ya formas parte de este equipo.',
        ),
      ),
    );
    expect((await bd.obtenerPartidos(lorgio)).single.cuposOcupados, 2);
  });

  test(
    'el último cupo completa el equipo y el siguiente es rechazado (criterios 2 y 3)',
    () async {
      final bd = ServicioAlmacenamiento();
      await bd.guardarPartidos(lorgio, [
        partidoDeLorgio(cuposTotales: 2, cuposOcupados: 1),
      ]);

      final unido = await bd.unirseAPartido(
        correoJugador: diego,
        nombreJugador: 'Diego',
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      );
      expect(unido.estado, EstadoPartido.equipoCompleto);

      await expectLater(
        bd.unirseAPartido(
          correoJugador: ana,
          nombreJugador: 'Ana',
          correoOrganizador: lorgio,
          partidoId: 'p-1',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'motivo',
            'Convocatoria cerrada: el equipo ya está completo.',
          ),
        ),
      );
      final guardado = (await bd.obtenerPartidos(lorgio)).single;
      expect(guardado.cuposOcupados, 2);
      expect(guardado.estado, EstadoPartido.equipoCompleto);
    },
  );

  test('el organizador no puede unirse a su propio partido', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [partidoDeLorgio()]);

    await expectLater(
      bd.unirseAPartido(
        correoJugador: lorgio,
        nombreJugador: 'Lorgio',
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      ),
      throwsStateError,
    );
    expect((await bd.obtenerPartidos(lorgio)).single.cuposOcupados, 1);
  });

  test(
    'si el organizador elimina el partido, desaparece de los partidos del jugador',
    () async {
      final bd = ServicioAlmacenamiento();
      await bd.guardarPartidos(lorgio, [partidoDeLorgio()]);
      await bd.unirseAPartido(
        correoJugador: diego,
        nombreJugador: 'Diego',
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      );

      await bd.guardarPartidos(lorgio, []);

      expect(await bd.obtenerPartidosUnidos(diego), isEmpty);
      expect(await bd.obtenerPartidosParaExplorar(diego), isEmpty);
    },
  );

  test('Issue #7: no se puede unir a un partido pasado y no se guarda nada', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [
      partidoDeLorgio(fechaHora: '01/03/2024 · 18:00'),
    ]);

    await expectLater(
      bd.unirseAPartido(
        correoJugador: diego,
        nombreJugador: 'Diego',
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'motivo',
          'El partido ya se jugó: su fecha ya pasó.',
        ),
      ),
    );
    expect((await bd.obtenerPartidos(lorgio)).single.cuposOcupados, 1);
    expect(await bd.obtenerPartidosUnidos(diego), isEmpty);
  });

  test('Issue #8: el organizador ve quién se unió, también al recargar', () async {
    final bd = ServicioAlmacenamiento();
    await bd.guardarPartidos(lorgio, [partidoDeLorgio()]);
    expect(await bd.obtenerJugadoresInscritos(lorgio), isEmpty);

    for (final (correo, nombre) in [(diego, 'Diego'), (ana, 'Ana')]) {
      await bd.unirseAPartido(
        correoJugador: correo,
        nombreJugador: nombre,
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      );
    }

    final inscritos = await ServicioAlmacenamiento().obtenerJugadoresInscritos(
      lorgio,
    );
    expect(inscritos['p-1'], ['Diego', 'Ana']);
  });

  test('una base de datos de la versión 2 se actualiza sin perder datos', () async {
    final carpeta = await Directory.systemTemp.createTemp('unisport_v2_');
    final ruta = '${carpeta.path}/unisport.db';

    // Base tal como quedó en los teléfonos con la versión anterior
    final vieja = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE partidos (
              correo_usuario TEXT NOT NULL, id TEXT NOT NULL,
              titulo TEXT NOT NULL, disciplina TEXT NOT NULL,
              icono TEXT NOT NULL, ubicacion TEXT NOT NULL,
              fecha_hora TEXT NOT NULL, cupos_totales INTEGER NOT NULL,
              cupos_ocupados INTEGER NOT NULL, organizador_nombre TEXT NOT NULL,
              soy_organizador INTEGER NOT NULL, estoy_unido INTEGER NOT NULL,
              estado TEXT NOT NULL, orden INTEGER NOT NULL,
              PRIMARY KEY (correo_usuario, id))
          ''');
          await db.execute('''
            CREATE TABLE inscripciones (
              correo_organizador TEXT NOT NULL, partido_id TEXT NOT NULL,
              correo_jugador TEXT NOT NULL,
              PRIMARY KEY (correo_organizador, partido_id, correo_jugador))
          ''');
        },
      ),
    );
    await vieja.insert('partidos', {
      'correo_usuario': lorgio, 'id': 'p-1', 'titulo': 'Futsal',
      'disciplina': 'Futsal', 'icono': 'Futsal', 'ubicacion': 'Cancha 2',
      'fecha_hora': '10/10/2099 · 19:00', 'cupos_totales': 10,
      'cupos_ocupados': 2, 'organizador_nombre': 'Lorgio',
      'soy_organizador': 1, 'estoy_unido': 1, 'estado': 'cuposAbiertos',
      'orden': 0,
    });
    await vieja.insert('inscripciones', {
      'correo_organizador': lorgio, 'partido_id': 'p-1', 'correo_jugador': diego,
    });
    await vieja.close();

    // La app nueva abre esa misma base
    await ServicioAlmacenamiento.reiniciarBaseDatos(ruta: ruta);
    final bd = ServicioAlmacenamiento();

    expect((await bd.obtenerPartidos(lorgio)).single.cuposOcupados, 2);
    // Inscripción antigua sin nombre: se muestra el correo
    expect((await bd.obtenerJugadoresInscritos(lorgio))['p-1'], [diego]);
    await bd.unirseAPartido(
      correoJugador: ana,
      nombreJugador: 'Ana',
      correoOrganizador: lorgio,
      partidoId: 'p-1',
    );
    expect((await bd.obtenerJugadoresInscritos(lorgio))['p-1'], [diego, 'Ana']);

    // La fecha real quedó guardada en la columna nueva
    await ServicioAlmacenamiento.reiniciarBaseDatos(ruta: inMemoryDatabasePath);
    final revisada = await databaseFactoryFfi.openDatabase(ruta);
    final fila = (await revisada.query('partidos')).single;
    expect(
      fila['fecha_inicio'],
      DateTime(2099, 10, 10, 19).millisecondsSinceEpoch,
    );
    await revisada.close();
    await carpeta.delete(recursive: true);
  });
}
