import 'package:flutter/material.dart';
import 'servicios/servicio_autenticacion.dart';
import 'tema/tema_app.dart';
import 'vistas/vista_inicio_publico.dart';
import 'vistas/vista_mis_partidos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de autenticación y cargar sesión persistida
  final servicioAuth = ServicioAutenticacion();
  await servicioAuth.inicializar();

  runApp(UniSportApp(servicioAuth: servicioAuth));
}

class UniSportApp extends StatelessWidget {
  final ServicioAutenticacion servicioAuth;

  const UniSportApp({
    super.key,
    required this.servicioAuth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: servicioAuth,
      builder: (context, _) {
        return MaterialApp(
          title: 'UniSport - IHC',
          debugShowCheckedModeBanner: false,
          theme: TemaApp.tema,
          // Si el servicio está cargando la sesión, mostrar pantalla de carga
          home: servicioAuth.estaCargando
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              // Si ya había una sesión persistida en el almacenamiento, entrar directo a Mis Partidos
              : (servicioAuth.estaAutenticado
                  ? VistaMisPartidos(servicioAuth: servicioAuth)
                  : VistaInicioPublico(servicioAuth: servicioAuth)),
        );
      },
    );
  }
}
