import 'package:flutter_test/flutter_test.dart';
import 'package:unisport/modelos/modelo_partido.dart';

/// Pruebas de la regla "¿Puede unirse al partido?" (Issue #2, historia #1).
/// Cada prueba corresponde a un criterio de aceptación de la historia.
///
/// Ejecutar con:  flutter test test/union_partido_test.dart
ModeloPartido crearPartido({
  bool soyOrganizador = false,
  bool estoyUnido = false,
  EstadoPartido estado = EstadoPartido.cuposAbiertos,
  int cuposTotales = 10,
  int cuposOcupados = 3,
}) {
  return ModeloPartido(
    id: 'p-1',
    titulo: 'Futsal nocturno',
    disciplina: 'Futsal',
    icono: 'Futsal',
    ubicacion: 'Cancha 2',
    fechaHora: '10/10/2026 · 19:00',
    cuposTotales: cuposTotales,
    cuposOcupados: cuposOcupados,
    organizadorNombre: 'Diego',
    soyOrganizador: soyOrganizador,
    estoyUnido: estoyUnido,
    estado: estado,
  );
}

void main() {
  group('¿Puede unirse al partido?', () {
    test(
      'Criterio 1 (permitido): un estudiante ajeno se une, los cupos suben en 1 y queda unido',
      () {
        final partido = crearPartido(cuposOcupados: 3);

        expect(partido.puedeUnirse, isTrue);
        expect(partido.motivoRechazoUnirse, isNull);

        final unido = partido.unirse();

        expect(unido.cuposOcupados, 4);
        expect(unido.estoyUnido, isTrue);
        expect(unido.estado, EstadoPartido.cuposAbiertos);
      },
    );

    test(
      'Criterio 2 (permitido): al ocupar el último cupo el partido pasa a Equipo completo',
      () {
        final partido = crearPartido(cuposTotales: 10, cuposOcupados: 9);

        final unido = partido.unirse();

        expect(unido.cuposOcupados, 10);
        expect(unido.estado, EstadoPartido.equipoCompleto);
      },
    );

    test(
      'Criterio 3 (rechazado): no puede unirse a un partido con el equipo completo',
      () {
        final completo = crearPartido(
          estado: EstadoPartido.equipoCompleto,
          cuposOcupados: 10,
        );

        expect(completo.puedeUnirse, isFalse);
        expect(
          completo.motivoRechazoUnirse,
          'Convocatoria cerrada: el equipo ya está completo.',
        );
        expect(() => completo.unirse(), throwsStateError);
        expect(completo.cuposOcupados, 10);
      },
    );

    test(
      'Criterio 4 (rechazado): quien ya forma parte del equipo no puede unirse otra vez',
      () {
        final yaUnido = crearPartido(estoyUnido: true, cuposOcupados: 4);

        expect(yaUnido.puedeUnirse, isFalse);
        expect(yaUnido.motivoRechazoUnirse, 'Ya formas parte de este equipo.');
        expect(() => yaUnido.unirse(), throwsStateError);
        expect(yaUnido.cuposOcupados, 4);
      },
    );

    test(
      'Criterio 4 (rechazado): el organizador no puede unirse a su propio partido',
      () {
        final propio = crearPartido(soyOrganizador: true, estoyUnido: true);

        expect(propio.puedeUnirse, isFalse);
        expect(propio.motivoRechazoUnirse, 'Ya formas parte de este equipo.');
        expect(() => propio.unirse(), throwsStateError);
      },
    );
  });
}
