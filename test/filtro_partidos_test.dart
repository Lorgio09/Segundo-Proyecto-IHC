import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unisport/modelos/filtro_partidos.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/servicios/servicio_almacenamiento.dart';

/// Pruebas de búsqueda y filtrado de partidos (Issues #9 y #11, requisito #6).
/// La consulta se resuelve en SQLite con datos guardados, no con datos de ejemplo.
///
/// Ejecutar con:  flutter test test/filtro_partidos_test.dart
const lorgio = 'lorgio@unisport.edu';
const ana = 'ana@unisport.edu';
const diego = 'diego@unisport.edu';

/// "Ahora" fijo para que las pruebas no dependan del día en que se ejecutan:
/// miércoles 15 de mayo de 2030 a mediodía.
final ahora = DateTime(2030, 5, 15, 12);

ModeloPartido partido(
  String id,
  String titulo,
  String disciplina,
  String lugar,
  String fechaHora, {
  int total = 10,
  int ocupados = 2,
  EstadoPartido estado = EstadoPartido.cuposAbiertos,
}) {
  return ModeloPartido(
    id: id,
    titulo: titulo,
    disciplina: disciplina,
    icono: disciplina,
    ubicacion: lugar,
    fechaHora: fechaHora,
    cuposTotales: total,
    cuposOcupados: ocupados,
    organizadorNombre: 'Organizador',
    soyOrganizador: true,
    estoyUnido: true,
    estado: estado,
  );
}

Future<List<String>> buscar(FiltroPartidos filtro) async {
  final resultado = await ServicioAlmacenamiento().buscarPartidos(
    diego,
    filtro,
    ahora: ahora,
  );
  return [for (final item in resultado) item.partido.id];
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ServicioAlmacenamiento.reiniciarBaseDatos(ruta: inMemoryDatabasePath);
    final bd = ServicioAlmacenamiento();

    await bd.guardarPartidos(lorgio, [
      // hoy, con cupos
      partido('hoy', 'Futsal nocturno', 'Futsal', 'Cancha Campus',
          '15/05/2030 · 19:00', ocupados: 3),
      // dentro de 7 días, equipo completo
      partido('completo', 'Básquet 3x3', 'Básquetbol', 'Coliseo Campus',
          '18/05/2030 · 18:00', total: 6, ocupados: 6,
          estado: EstadoPartido.equipoCompleto),
      // fuera de los próximos 7 días
      partido('junio', 'Vóley mixto', 'Voleibol', 'Estadio Módulo',
          '01/06/2030 · 10:00'),
      // ya pasó (antes de "ahora")
      partido('pasado', 'Futsal de práctica', 'Futsal', 'Coliseo Campus',
          '10/05/2030 · 09:00'),
    ]);
    await bd.guardarPartidos(ana, [
      partido('ana', 'Futsal femenino', 'Futsal', 'Cancha Campus 2',
          '20/05/2030 · 17:00', ocupados: 4),
    ]);
    // Partido de quien busca: nunca debe aparecer en sus resultados
    await bd.guardarPartidos(diego, [
      partido('propio', 'Futsal de Diego', 'Futsal', 'Cancha Diego',
          '16/05/2030 · 20:00'),
    ]);
  });

  group('Búsqueda por nombre', () {
    test('devuelve resultados sin distinguir mayúsculas', () async {
      expect(
        await buscar(const FiltroPartidos(texto: 'FUTSAL')),
        ['pasado', 'hoy', 'ana'],
      );
    });

    test('no devuelve nada si ningún partido coincide', () async {
      expect(await buscar(const FiltroPartidos(texto: 'rugby')), isEmpty);
    });

    test('los comodines escritos por el usuario se buscan como texto', () async {
      expect(await buscar(const FiltroPartidos(texto: '%')), isEmpty);
    });
  });

  group('Filtros', () {
    test('por deporte', () async {
      expect(
        await buscar(const FiltroPartidos(deporte: 'Voleibol')),
        ['junio'],
      );
    });

    test('por fecha: hoy', () async {
      expect(
        await buscar(const FiltroPartidos(fecha: FiltroFecha.hoy)),
        ['hoy'],
      );
    });

    test('por fecha: próximos 7 días', () async {
      expect(
        await buscar(const FiltroPartidos(fecha: FiltroFecha.proximos7Dias)),
        ['hoy', 'completo', 'ana'],
      );
    });

    test('por fecha: rango de fechas (días incluidos)', () async {
      expect(
        await buscar(
          FiltroPartidos(
            fecha: FiltroFecha.rango,
            desde: DateTime(2030, 6, 1),
            hasta: DateTime(2030, 6, 1),
          ),
        ),
        ['junio'],
      );
    });

    test('por lugar', () async {
      expect(
        await buscar(const FiltroPartidos(lugar: 'Coliseo Campus')),
        ['pasado', 'completo'],
      );
    });

    test(
      'solo con cupos: excluye equipos completos y partidos que ya pasaron',
      () async {
        expect(
          await buscar(const FiltroPartidos(soloConCupos: true)),
          ['hoy', 'ana', 'junio'],
        );
      },
    );

    test('nunca muestra los partidos propios', () async {
      final ids = await buscar(const FiltroPartidos());
      expect(ids, isNot(contains('propio')));
      expect(ids, hasLength(5));
    });
  });

  group('Filtros combinados', () {
    test('fútbol (Futsal) + esta semana + con cupos', () async {
      expect(
        await buscar(
          const FiltroPartidos(
            deporte: 'Futsal',
            fecha: FiltroFecha.proximos7Dias,
            soloConCupos: true,
          ),
        ),
        ['hoy', 'ana'],
      );
    });

    test('combinación sin coincidencias devuelve lista vacía', () async {
      expect(
        await buscar(
          const FiltroPartidos(deporte: 'Voleibol', fecha: FiltroFecha.hoy),
        ),
        isEmpty,
      );
    });
  });

  test('lugares: sugeridos más los existentes, sin repetir ni incluir los propios',
      () async {
    expect(await ServicioAlmacenamiento().obtenerLugares(diego), [
      'Cancha Campus',
      'Coliseo Campus',
      'Estadio Módulo',
      'Cancha Campus 2',
    ]);
  });

  test('la regla del navegador coincide con la consulta SQL', () async {
    final todos = await ServicioAlmacenamiento().buscarPartidos(
      diego,
      const FiltroPartidos(),
      ahora: ahora,
    );
    final filtros = [
      const FiltroPartidos(texto: 'futsal'),
      const FiltroPartidos(fecha: FiltroFecha.proximos7Dias, soloConCupos: true),
      const FiltroPartidos(lugar: 'cancha campus'),
      const FiltroPartidos(deporte: 'Básquetbol', soloConCupos: true),
    ];
    for (final filtro in filtros) {
      final enMemoria = [
        for (final item in todos)
          if (filtro.coincide(item.partido, ahora)) item.partido.id,
      ];
      expect(enMemoria, await buscar(filtro));
    }
  });

  group('Estado del filtro', () {
    test('sin filtros no está activo; con cualquiera sí', () {
      expect(const FiltroPartidos().estaActivo, isFalse);
      expect(const FiltroPartidos(soloConCupos: true).estaActivo, isTrue);
      expect(const FiltroPartidos(texto: '  ').estaActivo, isFalse);
    });

    test('se puede quitar un filtro sin perder los demás', () {
      const filtro = FiltroPartidos(deporte: 'Futsal', lugar: 'Coliseo Campus');

      final sinDeporte = filtro.copiarCon(quitarDeporte: true);

      expect(sinDeporte.deporte, isNull);
      expect(sinDeporte.lugar, 'Coliseo Campus');
    });
  });
}
