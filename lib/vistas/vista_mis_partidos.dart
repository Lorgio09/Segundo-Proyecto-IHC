import 'package:flutter/material.dart';
import '../modelos/modelo_partido.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import 'vista_login.dart';

/// Ruta Privada: Mis Partidos (Protegida)
/// Si un usuario sin sesión intenta acceder, se redirige inmediatamente a la pantalla de Login.
class VistaMisPartidos extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaMisPartidos({
    super.key,
    required this.servicioAuth,
  });

  @override
  State<VistaMisPartidos> createState() => _VistaMisPartidosState();
}

class _VistaMisPartidosState extends State<VistaMisPartidos> {
  // Lista de partidos de ejemplo asociados al estudiante autenticado
  late List<ModeloPartido> _partidos;
  String _filtroActivo = 'todos';

  @override
  void initState() {
    super.initState();
    _verificarAccesoProtegido();
    _cargarPartidosSemilla();
  }

  // Verificación de Ruta Privada Protegida
  void _verificarAccesoProtegido() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.servicioAuth.estaAutenticado) {
        // Redirección inmediata al Login por falta de sesión
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VistaLogin(
              servicioAuth: widget.servicioAuth,
              mensajeRedireccion: '🛡️ Acceso Denegado: Debes iniciar sesión para acceder a "Mis Partidos".',
            ),
          ),
        );
      }
    });
  }

  void _cargarPartidosSemilla() {
    _partidos = [
      ModeloPartido(
        id: 'p-01',
        titulo: 'Futsal 5 vs 5 · Nocturno',
        disciplina: 'Futsal',
        icono: '⚽',
        ubicacion: 'Cancha 2 (Campus Central)',
        fechaHora: 'Hoy · 19:30',
        cuposTotales: 10,
        cuposOcupados: 8,
        nivel: 'Medio',
        organizadorNombre: widget.servicioAuth.usuarioActual?.nombre ?? 'Diego Astete',
        soyOrganizador: true,
        estoyUnido: true,
      ),
      ModeloPartido(
        id: 'p-02',
        titulo: 'Básquet 3x3 · Amistoso',
        disciplina: 'Básquetbol',
        icono: '🏀',
        ubicacion: 'Coliseo Polideportivo',
        fechaHora: 'Mañana · 11:00',
        cuposTotales: 6,
        cuposOcupados: 5,
        nivel: 'Recreativo',
        organizadorNombre: 'Carlos Méndez',
        soyOrganizador: false,
        estoyUnido: true,
      ),
      ModeloPartido(
        id: 'p-03',
        titulo: 'Voleibol Mixto Interfacultades',
        disciplina: 'Voleibol',
        icono: '🏐',
        ubicacion: 'Cancha de Arena',
        fechaHora: 'Viernes · 16:00',
        cuposTotales: 12,
        cuposOcupados: 12,
        nivel: 'Competitivo',
        organizadorNombre: 'Lorgio Choque',
        soyOrganizador: false,
        estoyUnido: true,
      ),
    ];
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: TemaApp.borde, width: 2.5),
        ),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Volverás a la pantalla pública de UniSport.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: TemaApp.textoSecundario, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp.rojoAlerta,
              minimumSize: const Size(110, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await widget.servicioAuth.cerrarSesion();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final partidosFiltrados = _partidos.where((p) {
      if (_filtroActivo == 'organizados') return p.soyOrganizador;
      if (_filtroActivo == 'unido') return !p.soyOrganizador;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Partidos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout, color: TemaApp.rojoAlerta),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Usuario Autenticado (Requisito explícito del docente)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TemaApp.borde, width: TemaApp.grosorBordeAncho),
                boxShadow: const [
                  BoxShadow(
                    color: TemaApp.borde,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: TemaApp.amarilloInsignia,
                    child: Text(
                      usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: TemaApp.textoPrincipal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                usuario.nombre,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: TemaApp.textoPrincipal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: TemaApp.verdeDeportivo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Activo',
                                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${usuario.correo} · ${usuario.carrera}',
                          style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Filtros de pestaña
            Row(
              children: [
                _construirBotonFiltro('Todos (${_partidos.length})', 'todos'),
                const SizedBox(width: 8),
                _construirBotonFiltro('Creados por mí', 'organizados'),
                const SizedBox(width: 8),
                _construirBotonFiltro('Como Jugador', 'unido'),
              ],
            ),

            const SizedBox(height: 18),

            // Encabezado de Lista
            Text(
              'Encuentros Programados (${partidosFiltrados.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: TemaApp.textoPrincipal),
            ),

            const SizedBox(height: 12),

            // Lista de Tarjetas con Bordes Anchos
            if (partidosFiltrados.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
                child: const Column(
                  children: [
                    Text('🏃', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 10),
                    Text(
                      'No tienes partidos en esta categoría.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: TemaApp.textoSecundario),
                    ),
                  ],
                ),
              )
            else
              ...partidosFiltrados.map((partido) => _construirTarjetaPartido(partido)),

            const SizedBox(height: 20),

            // Botón de Cerrar Sesión
            OutlinedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout, color: TemaApp.rojoAlerta),
              label: const Text('CERRAR SESIÓN DE ESTUDIANTE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaApp.rojoAlerta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotonFiltro(String texto, String clave) {
    final activo = _filtroActivo == clave;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtroActivo = clave),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? TemaApp.textoPrincipal : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TemaApp.borde, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: activo ? Colors.white : TemaApp.textoPrincipal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaPartido(ModeloPartido partido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemaApp.borde, width: TemaApp.grosorBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TemaApp.borde, width: 1.5),
                ),
                child: Text(partido.icono, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partido.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: TemaApp.textoPrincipal),
                    ),
                    Text(
                      '${partido.ubicacion} · ${partido.fechaHora}',
                      style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
                    ),
                  ],
                ),
              ),
              if (partido.soyOrganizador)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TemaApp.azulDeportivo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Organizador',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: TemaApp.textoSecundario),
                  const SizedBox(width: 4),
                  Text(
                    '${partido.cuposOcupados}/${partido.cuposTotales} jugadores',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TemaApp.textoPrincipal),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: partido.estaLleno ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: partido.estaLleno ? TemaApp.verdeDeportivo : const Color(0xFFD97706),
                  ),
                ),
                child: Text(
                  partido.estaLleno ? '✓ Equipo Completo' : 'Faltan ${partido.cuposRestantes} cupos',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: partido.estaLleno ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
