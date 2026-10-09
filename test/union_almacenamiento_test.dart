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
}) {
  return ModeloPartido(
    id: id,
    titulo: 'Futsal nocturno',
    disciplina: 'Futsal',
    icono: 'Futsal',
    ubicacion: 'Cancha 2',
    fechaHora: '10/10/2026 · 19:00',
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
      correoOrganizador: lorgio,
      partidoId: 'p-1',
    );

    await expectLater(
      bd.unirseAPartido(
        correoJugador: diego,
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
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      );
      expect(unido.estado, EstadoPartido.equipoCompleto);

      await expectLater(
        bd.unirseAPartido(
          correoJugador: ana,
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
        correoOrganizador: lorgio,
        partidoId: 'p-1',
      );

      await bd.guardarPartidos(lorgio, []);

      expect(await bd.obtenerPartidosUnidos(diego), isEmpty);
      expect(await bd.obtenerPartidosParaExplorar(diego), isEmpty);
    },
  );
}
