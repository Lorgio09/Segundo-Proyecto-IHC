import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unisport/modelos/modelo_partido.dart';
import 'package:unisport/servicios/servicio_almacenamiento.dart';
import 'package:unisport/servicios/servicio_autenticacion.dart';
import 'package:unisport/vistas/vista_explorar_partidos.dart';

/// Prueba de punta a punta del requisito #6:
/// interfaz (Explorar) -> consulta (buscarPartidos) -> base de datos SQLite.
///
/// Ejecutar con:  flutter test test/explorar_filtros_test.dart
/// (Los avisos de google_fonts en consola son normales: la prueba no descarga
/// la tipografía de internet; no afectan el resultado.)
ModeloPartido partido(String id, String titulo, String disciplina) {
  return ModeloPartido(
    id: id,
    titulo: titulo,
    disciplina: disciplina,
    icono: disciplina,
    ubicacion: 'Coliseo Campus',
    fechaHora: '10/10/2099 · 19:00',
    cuposTotales: 10,
    cuposOcupados: 2,
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

  testWidgets('filtrar desde la pantalla consulta la base de datos', (
    tester,
  ) async {
    final auth = ServicioAutenticacion();

    // Las operaciones reales de base de datos se ejecutan fuera del reloj falso
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      await ServicioAlmacenamiento.reiniciarBaseDatos(
        ruta: inMemoryDatabasePath,
      );
      await ServicioAlmacenamiento().guardarPartidos('lorgio@unisport.edu', [
        partido('a', 'Futsal nocturno', 'Futsal'),
        partido('b', 'Vóley mixto', 'Voleibol'),
      ]);
      await auth.inicializar();
      await auth.iniciarSesion('diego@unisport.edu', '123456');
    });

    Future<void> esperarConsulta() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
    }

    await tester.pumpWidget(
      MaterialApp(home: VistaExplorarPartidos(servicioAuth: auth)),
    );
    await esperarConsulta();

    expect(find.text('2 partidos encontrados'), findsOneWidget);

    // Búsqueda con resultados
    await tester.enterText(find.byType(TextField), 'vóley');
    await esperarConsulta();
    expect(find.text('1 partido encontrado'), findsOneWidget);
    expect(find.text('Vóley mixto'), findsOneWidget);
    expect(find.text('Futsal nocturno'), findsNothing);

    // Búsqueda sin resultados: mensaje claro en lugar de lista vacía
    await tester.enterText(find.byType(TextField), 'rugby');
    await esperarConsulta();
    expect(
      find.text('Ningún partido coincide con tu búsqueda'),
      findsOneWidget,
    );

    // Quitar filtros vuelve a mostrar todo
    await tester.tap(find.text('Quitar filtros'));
    await esperarConsulta();
    expect(find.text('2 partidos encontrados'), findsOneWidget);
  });
}
