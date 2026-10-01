import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import 'vista_login.dart';
import 'vista_registro.dart';
import 'vista_mis_partidos.dart';

/// Ruta Pública: Portada de bienvenida a UniSport accesible sin sesión
class VistaInicioPublico extends StatelessWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaInicioPublico({
    super.key,
    required this.servicioAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TemaApp.verdeDeportivo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TemaApp.borde, width: 2),
              ),
              child: const Text('⚽', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Text(
              'UniSport',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: TemaApp.textoPrincipal,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TemaApp.amarilloInsignia,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TemaApp.borde, width: 2),
            ),
            child: const Text(
              'Pública',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: TemaApp.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta Hero con Borde Ancho
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: TemaApp.azulDeportivo,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TemaApp.borde, width: TemaApp.grosorBordeAncho),
                boxShadow: const [
                  BoxShadow(
                    color: TemaApp.borde,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TemaApp.borde, width: 2),
                    ),
                    child: const Text(
                      'IHC · PROYECTO 2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: TemaApp.textoPrincipal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Crea Partidos y Completa tu Equipo!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La plataforma universitaria para coordinar encuentros deportivos en las canchas del campus sin fricción.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE0E7FF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Estado de Sesión Actual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.borde, width: TemaApp.grosorBorde),
              ),
              child: Row(
                children: [
                  Icon(
                    servicioAuth.estaAutenticado ? Icons.check_circle : Icons.lock_outline,
                    color: servicioAuth.estaAutenticado ? TemaApp.verdeDeportivo : TemaApp.textoSecundario,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicioAuth.estaAutenticado ? 'Sesión Iniciada' : 'Navegación como Invitado',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: TemaApp.textoPrincipal,
                          ),
                        ),
                        Text(
                          servicioAuth.estaAutenticado
                              ? 'Conectado como: ${servicioAuth.usuarioActual!.nombre}'
                              : 'Inicia sesión para gestionar "Mis Partidos"',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaApp.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones de Acción
            if (!servicioAuth.estaAutenticado) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VistaLogin(servicioAuth: servicioAuth),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('INICIAR SESIÓN'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VistaRegistro(servicioAuth: servicioAuth),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt),
                label: const Text('CREAR NUEVA CUENTA'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VistaMisPartidos(servicioAuth: servicioAuth),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.verdeDeportivo,
                ),
                icon: const Icon(Icons.sports_soccer),
                label: const Text('IR A MIS PARTIDOS (PRIVADA)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await servicioAuth.cerrarSesion();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sesión cerrada correctamente.'),
                        backgroundColor: TemaApp.textoPrincipal,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESIÓN'),
              ),
            ],

            const SizedBox(height: 18),

            // Botón de Prueba de Protección de Ruta (Demostración para el docente)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD97706), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛡️ Prueba de Ruta Protegida (Para el Docente):',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Presiona el botón para verificar que el acceso no autorizado a "Mis Partidos" es bloqueado y redirige al Login.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VistaMisPartidos(servicioAuth: servicioAuth),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security, size: 18),
                    label: const Text('Probar acceso directo a Ruta Privada'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF92400E),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Footer con Integrantes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Text(
                    'Proyecto 2 · Interacción Humano-Computador',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TemaApp.textoSecundario),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Diego Astete Paz · Lorgio Leonardo Choque Severiche',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TemaApp.textoPrincipal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
