import 'package:flutter_test/flutter_test.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'apoyo/repositorio_en_memoria.dart';

/// Pruebas unitarias de la regla de cambio de estado:
///   Cupos abiertos --(Completar equipo)--> Equipo completo
///
/// Ejecutar con:  flutter test test/estado_partido_test.dart
ModeloPartido crearPartido({
  bool soyOrganizador = true,
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
    fechaHora: '10/10/2099 · 19:00',
    cuposTotales: cuposTotales,
    cuposOcupados: cuposOcupados,
    organizadorNombre: 'Lorgio',
    soyOrganizador: soyOrganizador,
    estoyUnido: soyOrganizador,
    estado: estado,
  );
}

void main() {
  group('Regla de cambio de estado: completar equipo', () {
    test('un partido nuevo nace con los cupos abiertos', () {
      final partido = crearPartido();

      expect(partido.estado, EstadoPartido.cuposAbiertos);
      expect(partido.puedeCompletarEquipo, isTrue);
    });

    test('el organizador pasa el partido de Cupos abiertos a Equipo completo', () {
      final partido = crearPartido();

      final completo = partido.completarEquipo();

      expect(completo.estado, EstadoPartido.equipoCompleto);
      expect(completo.estado.etiqueta, 'Equipo completo');
    });

    test('al completar el equipo todos los cupos quedan ocupados', () {
      final completo = crearPartido(
        cuposTotales: 10,
        cuposOcupados: 3,
      ).completarEquipo();

      expect(completo.cuposOcupados, 10);
      expect(completo.cuposRestantes, 0);
      expect(completo.estaLleno, isTrue);
    });

    test('no se puede completar un equipo que ya está completo', () {
      final completo = crearPartido().completarEquipo();

      expect(completo.puedeCompletarEquipo, isFalse);
      expect(() => completo.completarEquipo(), throwsStateError);
    });

    test('quien no es organizador no puede completar el equipo', () {
      final ajeno = crearPartido(soyOrganizador: false);

      expect(ajeno.puedeCompletarEquipo, isFalse);
      expect(() => ajeno.completarEquipo(), throwsStateError);
    });

    test('completar el equipo no modifica el partido original', () {
      final original = crearPartido(cuposOcupados: 3);

      original.completarEquipo();

      expect(original.estado, EstadoPartido.cuposAbiertos);
      expect(original.cuposOcupados, 3);
    });
  });

  group('Conservar el cambio después de recargar', () {
    test('el estado Equipo completo queda guardado en el repositorio', () async {
      final repositorio = RepositorioEnMemoria(
        usuarioId: 'u-lorgio',
        usuarioNombre: 'Lorgio',
      );
      final creado = await repositorio.crearPartido(crearPartido());

      await repositorio.completarEquipo(creado.id);

      // Volver a leer = recargar la pantalla
      final recuperado = (await repositorio.obtenerMisPartidos()).single;
      expect(recuperado.estado, EstadoPartido.equipoCompleto);
      expect(recuperado.cuposOcupados, recuperado.cuposTotales);
    });

    test('la fecha real se convierte al texto de la pantalla y de vuelta', () {
      final fecha = DateTime(2099, 6, 15, 9, 30);

      final texto = ModeloPartido.formatearFechaHora(fecha);

      expect(texto, '15/06/2099 · 09:30');
      expect(ModeloPartido.interpretarFechaHora(texto), fecha);
    });

    test('un partido guardado sin estado se recupera con cupos abiertos', () {
      final json = crearPartido().toJson()..remove('estado');

      final partido = ModeloPartido.fromJson(json);

      expect(partido.estado, EstadoPartido.cuposAbiertos);
    });
  });
}
