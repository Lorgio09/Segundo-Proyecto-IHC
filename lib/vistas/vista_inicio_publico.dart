import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import 'vista_login.dart';
import 'vista_registro.dart';
import 'vista_mis_partidos.dart';

/// Ruta Pública: Portada de bienvenida a UniSport accesible sin sesión
class VistaInicioPublico extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaInicioPublico({
    super.key,
    required this.servicioAuth,
  });

  @override
  State<VistaInicioPublico> createState() => _VistaInicioPublicoState();
}

class _VistaInicioPublicoState extends State<VistaInicioPublico> {
  final int _indiceNavegacion = 0;

  void _alSeleccionarPestana(int indice) {
    if (indice == 1) {
      // Intento de acceder a Mis Partidos (Ruta Privada)
      if (widget.servicioAuth.estaAutenticado) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VistaMisPartidos(servicioAuth: widget.servicioAuth),
          ),
        );
      } else {
        // Redirección natural al login por falta de sesión
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VistaLogin(
              servicioAuth: widget.servicioAuth,
              mensajeRedireccion: 'Inicia sesión para ver tus partidos.',
            ),
          ),
        );
      }
    }
  }

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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta Hero Principal
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Crea Partidos y Completa tu Equipo!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
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

                // Disciplinas Deportivas
                const Text(
                  'Disciplinas Disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: TemaApp.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _ChipDisciplina(icono: '⚽', nombre: 'Futsal'),
                    SizedBox(width: 8),
                    _ChipDisciplina(icono: '🏀', nombre: 'Básquet'),
                    SizedBox(width: 8),
                    _ChipDisciplina(icono: '🏐', nombre: 'Vóley'),
                  ],
                ),

                const SizedBox(height: 28),

                // Acciones de Acceso
                if (!widget.servicioAuth.estaAutenticado) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VistaLogin(servicioAuth: widget.servicioAuth),
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
                          builder: (_) => VistaRegistro(servicioAuth: widget.servicioAuth),
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
                          builder: (_) => VistaMisPartidos(servicioAuth: widget.servicioAuth),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaApp.verdeDeportivo,
                    ),
                    icon: const Icon(Icons.sports_soccer),
                    label: const Text('VER MIS PARTIDOS'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceNavegacion,
        onTap: _alSeleccionarPestana,
        selectedItemColor: TemaApp.textoPrincipal,
        unselectedItemColor: TemaApp.textoSecundario,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Mis Partidos',
          ),
        ],
      ),
    );
  }
}

class _ChipDisciplina extends StatelessWidget {
  final String icono;
  final String nombre;

  const _ChipDisciplina({required this.icono, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TemaApp.borde, width: TemaApp.grosorBorde),
        ),
        child: Column(
          children: [
            Text(icono, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: TemaApp.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
