import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/widgets/tarjeta_partido.dart';

/// Pruebas de la interfaz: la acción "Agregar jugador" y su bloqueo
/// cuando el equipo está completo.
///
/// Ejecutar con:  flutter test test/tarjeta_partido_test.dart
ModeloPartido crearPartido({EstadoPartido estado = EstadoPartido.cuposAbiertos}) {
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
    soyOrganizador: true,
    estoyUnido: true,
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
}
