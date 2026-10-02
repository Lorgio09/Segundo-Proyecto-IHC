import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../modelos/modelo_partido.dart';
import '../servicios/servicio_almacenamiento.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import '../widgets/tarjeta_partido.dart';
import 'vista_crear_partido.dart';
import 'vista_login.dart';

/// Ruta Privada: Mis Partidos (Protegida)
/// Si un usuario sin sesión intenta acceder, se redirige inmediatamente a la pantalla de Login.
///
/// Funcionalidad vertical (Clase 13):
/// 1 Capturar -> 2 Construir -> 3 Guardar -> 4 Mostrar -> 5 Recuperar
class VistaMisPartidos extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaMisPartidos({super.key, required this.servicioAuth});

  @override
  State<VistaMisPartidos> createState() => _VistaMisPartidosState();
}

class _VistaMisPartidosState extends State<VistaMisPartidos> {
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();
  List<ModeloPartido> _partidos = [];
  bool _cargando = true;
  String _filtroActivo = 'todos';

  @override
  void initState() {
    super.initState();
    _verificarAccesoProtegido();
    _cargarPartidos();
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
              mensajeRedireccion:
                  'Debes iniciar sesión para acceder a "Mis Partidos".',
            ),
          ),
        );
      }
    });
  }

  // 5 - RECUPERAR: lee lo guardado al abrir la pantalla.
  Future<void> _cargarPartidos() async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) return;

    final guardados = await _almacenamiento.obtenerPartidos(usuario.correo);
    if (!mounted) return;

    setState(() {
      _partidos = guardados;
      _cargando = false;
    });
  }

  // 1-4: CAPTURAR (formulario) -> CONSTRUIR -> GUARDAR -> MOSTRAR
  Future<void> _crearPartido() async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) return;

    // 1 y 2: el formulario captura los datos y devuelve el ModeloPartido construido
    final nuevo = await Navigator.push<ModeloPartido>(
      context,
      MaterialPageRoute(
        builder: (_) => VistaCrearPartido(organizadorNombre: usuario.nombre),
      ),
    );

    // Si la persona volvió atrás sin guardar, no se hace nada
    if (nuevo == null || !mounted) return;

    // 3: GUARDAR
    final nuevaLista = [nuevo, ..._partidos];
    await _almacenamiento.guardarPartidos(usuario.correo, nuevaLista);
    if (!mounted) return;

    // 4: MOSTRAR
    setState(() {
      _partidos = nuevaLista;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partido "${nuevo.titulo}" creado y guardado')),
    );
  }

  // ACCIÓN "COMPLETAR EQUIPO": aplica la regla del modelo, guarda y muestra el resultado
  Future<void> _completarEquipo(ModeloPartido partido) async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null || !partido.puedeCompletarEquipo) return;

    final actualizado = partido.completarEquipo();
    final nuevaLista = [
      for (final p in _partidos) p.id == partido.id ? actualizado : p,
    ];

    // GUARDAR: el cambio sobrevive a recargar la app
    await _almacenamiento.guardarPartidos(usuario.correo, nuevaLista);
    if (!mounted) return;

    setState(() => _partidos = nuevaLista);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Equipo completo en "${partido.titulo}"!')),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Cerrar sesión?', style: TemaApp.titulo(tamano: 20)),
        content: const Text('Volverás a la pantalla pública de UniSport.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: TemaApp.textoSecundario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp.rojoAlerta,
              minimumSize: const Size(110, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final partidosFiltrados = _partidos.where((p) {
      if (_filtroActivo == 'organizados') return p.soyOrganizador;
      if (_filtroActivo == 'unido') return !p.soyOrganizador;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis partidos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              LucideIcons.logOut,
              color: TemaApp.rojoAlerta,
              size: 20,
            ),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearPartido,
        backgroundColor: TemaApp.verdeDeportivo,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text(
          'Crear partido',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _construirBannerUsuario(
                  usuario.nombre,
                  usuario.correo,
                  usuario.carrera,
                ),
                const SizedBox(height: 24),
                _construirEncabezadoLista(partidosFiltrados.length),
                const SizedBox(height: 12),
                _construirFiltros(),
                const SizedBox(height: 16),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (partidosFiltrados.isEmpty)
                  _construirEstadoVacio()
                else
                  ...partidosFiltrados.map(
                    (p) => TarjetaPartido(
                      partido: p,
                      onCompletarEquipo: () => _completarEquipo(p),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Banner de usuario autenticado (requisito explícito del docente)
  Widget _construirBannerUsuario(String nombre, String correo, String carrera) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF0F766E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3316A34A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: TemaApp.titulo(tamano: 20, color: TemaApp.verdeOscuro),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TemaApp.titulo(tamano: 17, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  '$correo · $carrera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circleDot, size: 11, color: Color(0xFFBBF7D0)),
                SizedBox(width: 5),
                Text(
                  'Activo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEncabezadoLista(int cantidad) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Encuentros programados',
            style: TemaApp.titulo(tamano: 18),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: TemaApp.verdeSuave,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$cantidad',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: TemaApp.verdeOscuro,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirFiltros() {
    return Row(
      children: [
        _construirBotonFiltro('Todos (${_partidos.length})', 'todos'),
        const SizedBox(width: 8),
        _construirBotonFiltro('Creados por mí', 'organizados'),
        const SizedBox(width: 8),
        _construirBotonFiltro('Como jugador', 'unido'),
      ],
    );
  }

  Widget _construirBotonFiltro(String texto, String clave) {
    final activo = _filtroActivo == clave;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtroActivo = clave),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? TemaApp.textoPrincipal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo ? TemaApp.textoPrincipal : TemaApp.borde,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : TemaApp.textoSecundario,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirEstadoVacio() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: TemaApp.tarjeta(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: TemaApp.verdeSuave,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.calendarDays,
              size: 28,
              color: TemaApp.verdeOscuro,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No tienes partidos en esta categoría',
            textAlign: TextAlign.center,
            style: TemaApp.titulo(tamano: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca "Crear partido" para agregar uno.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: TemaApp.textoSecundario),
          ),
        ],
      ),
    );
  }
}
