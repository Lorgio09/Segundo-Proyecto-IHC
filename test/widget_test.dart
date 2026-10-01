import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisport/main.dart';
import 'package:unisport/servicios/servicio_autenticacion.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Verifica renderizado de ruta publica de UniSport', (WidgetTester tester) async {
    final servicioAuth = ServicioAutenticacion();
    await servicioAuth.inicializar();

    await tester.pumpWidget(UniSportApp(servicioAuth: servicioAuth));
    await tester.pumpAndSettle();

    // Verificar que el título UniSport y los botones de acceso se muestren en la ruta pública
    expect(find.text('UniSport'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('CREAR NUEVA CUENTA'), findsOneWidget);
  });
}
