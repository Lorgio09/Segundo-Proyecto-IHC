import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/widgets/tarjeta_partido.dart';

/// Pruebas de la interfaz: la acción "Agregar jugador" y su bloqueo
/// cuando el equipo está completo, y la acción "Unirme al equipo" con el
/// motivo de cada rechazo (Issue #4).
///
/// Ejecutar con:  flutter test test/tarjeta_partido_test.dart
ModeloPartido crearPartido({
  EstadoPartido estado = EstadoPartido.cuposAbiertos,
  bool soyOrganizador = true,
  bool estoyUnido = true,
}) {
  return ModeloPartido(
    id: 'p-1',
    titulo: 'Futsal nocturno',
    disciplina: 'Futsal',
    icono: 'Futsal',
    ubicacion: 'Cancha 2',
    fechaHora: '10/10/2026 · 19:00',
    cuposTotales: 10,
    cuposOcupados: estado == EstadoPartido.equipoCompleto ? 10 : 3,
    organizadorNombre: 'Lorgio',
    soyOrganizador: soyOrganizador,
    estoyUnido: estoyUnido,
    estado: estado,
  );
}

Widget envolver(Widget hijo) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo)));

void main() {
  testWidgets('con cupos abiertos se puede agregar un jugador y no hay aviso de bloqueo', (
    tester,
  ) async {
    var llamadas = 0;
    await tester.pumpWidget(
      envolver(
        TarjetaPartido(
          partido: crearPartido(),
          onAgregarJugador: () => llamadas++,
          onCompletarEquipo: () {},
        ),
      ),
    );

    await tester.tap(find.text('Agregar jugador'));

    expect(llamadas, 1);
    expect(find.textContaining('No puedes agregar más jugadores'), findsNothing);
  });

  testWidgets('con el equipo completo la interfaz explica por qué no se pueden agregar jugadores', (
    tester,
  ) async {
    await tester.pumpWidget(
      envolver(
        TarjetaPartido(
          partido: crearPartido(estado: EstadoPartido.equipoCompleto),
          onAgregarJugador: () {},
          onCompletarEquipo: () {},
        ),
      ),
    );

    expect(find.textContaining('No puedes agregar más jugadores'), findsOneWidget);
    expect(find.textContaining('el equipo ya está completo'), findsOneWidget);
    // El botón "Completar equipo" ya no se ofrece
    expect(find.text('Completar equipo'), findsNothing);
  });

  group('Unirme al equipo (Issue #4)', () {
    testWidgets('con cupos abiertos aparece el botón y avisa al tocarlo', (
      tester,
    ) async {
      var llamadas = 0;
      await tester.pumpWidget(
        envolver(
          TarjetaPartido(
            partido: crearPartido(soyOrganizador: false, estoyUnido: false),
            onUnirse: () => llamadas++,
          ),
        ),
      );

      expect(find.text('Organiza: Lorgio'), findsOneWidget);
      await tester.tap(find.text('Unirme al equipo'));

      expect(llamadas, 1);
      expect(find.textContaining('No puedes unirte'), findsNothing);
    });

    testWidgets('con el equipo completo no hay botón y se explica el motivo', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolver(
          TarjetaPartido(
            partido: crearPartido(
              estado: EstadoPartido.equipoCompleto,
              soyOrganizador: false,
              estoyUnido: false,
            ),
            onUnirse: () {},
          ),
        ),
      );

      expect(find.text('Unirme al equipo'), findsNothing);
      expect(
        find.text(
          'No puedes unirte. Convocatoria cerrada: el equipo ya está completo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('si ya forma parte del equipo no hay botón y se indica', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolver(
          TarjetaPartido(
            partido: crearPartido(soyOrganizador: false, estoyUnido: true),
            onUnirse: () {},
          ),
        ),
      );

      expect(find.text('Unirme al equipo'), findsNothing);
      expect(find.text('Ya formas parte de este equipo.'), findsOneWidget);
    });
  });
}
