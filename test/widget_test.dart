import 'package:flutter_test/flutter_test.dart';
import 'package:unisport/main.dart';

import 'apoyo/servicio_autenticacion_falso.dart';

void main() {
  testWidgets('Verifica renderizado de ruta publica de UniSport', (
    WidgetTester tester,
  ) async {
    final servicioAuth = ServicioAutenticacionFalso();
    await servicioAuth.inicializar();

    await tester.pumpWidget(UniSportApp(servicioAuth: servicioAuth));
    await tester.pumpAndSettle();

    // Verificar que el título UniSport y los botones de acceso se muestren en la ruta pública
    expect(find.text('UniSport'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear nueva cuenta'), findsOneWidget);
  });
}
