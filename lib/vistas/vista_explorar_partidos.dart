import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../modelos/filtro_partidos.dart';
import '../modelos/modelo_partido.dart';
import '../servicios/servicio_almacenamiento.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import '../widgets/panel_filtros.dart';
import '../widgets/tarjeta_partido.dart';

/// Explorar partidos organizados por otros estudiantes, buscarlos, filtrarlos
/// (requisito #6) y unirse a ellos (requisito #5).
class VistaExplorarPartidos extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaExplorarPartidos({super.key, required this.servicioAuth});

  @override
  State<VistaExplorarPartidos> createState() => _VistaExplorarPartidosState();
}

class _VistaExplorarPartidosState extends State<VistaExplorarPartidos> {
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();
  List<PartidoPublicado> _partidos = [];
  List<String> _lugares = FiltroPartidos.lugaresSugeridos;
  FiltroPartidos _filtro = const FiltroPartidos();
  bool _cargando = true;

  // Evita que una consulta lenta pise el resultado de una más reciente
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Interfaz -> consulta -> base de datos: cada cambio de filtro vuelve a
  // pedir los partidos a SQLite con buscarPartidos.
  Future<void> _cargar() async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) return;

    final numero = ++_consulta;
    final partidos = await _almacenamiento.buscarPartidos(
      usuario.correo,
      _filtro,
    );
    final lugares = await _almacenamiento.obtenerLugares(usuario.correo);
    if (!mounted || numero != _consulta) return;
    setState(() {
      _partidos = partidos;
      _lugares = lugares;
      _cargando = false;
    });
  }

  void _cambiarFiltro(FiltroPartidos nuevo) {
    setState(() => _filtro = nuevo);
    _cargar();
  }

  void _avisar(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? TemaApp.rojoAlerta : null,
      ),
    );
  }

  // ACCIÓN "UNIRME AL EQUIPO": la regla del modelo decide; si rechaza, se explica el motivo
  Future<void> _unirse(PartidoPublicado item) async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) return;

    final motivo = item.partido.motivoRechazoUnirse;
    if (motivo != null) {
      _avisar('No puedes unirte. $motivo', error: true);
      return;
    }

    try {
      final unido = await _almacenamiento.unirseAPartido(
        correoJugador: usuario.correo,
        nombreJugador: usuario.nombre,
        correoOrganizador: item.correoOrganizador,
        partidoId: item.partido.id,
      );
      if (!mounted) return;

      setState(() {
        _partidos = [
          for (final p in _partidos)
            p.correoOrganizador == item.correoOrganizador &&
                    p.partido.id == item.partido.id
                ? (correoOrganizador: p.correoOrganizador, partido: unido)
                : p,
        ];
      });

      final completo = unido.estado == EstadoPartido.equipoCompleto;
      _avisar(
        '¡Te uniste a "${unido.titulo}"! '
        '(${unido.cuposOcupados}/${unido.cuposTotales})'
        '${completo ? ' El equipo quedó completo.' : ''}',
      );
    } on StateError catch (e) {
      // El dato guardado cambió (por ejemplo, otro ocupó el último cupo)
      if (!mounted) return;
      _avisar('No puedes unirte. ${e.message}', error: true);
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar partidos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: _cargar,
            color: TemaApp.verdeDeportivo,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Partidos organizados por otros estudiantes. Únete a los que tengan cupos abiertos.',
                  style: TextStyle(
                    fontSize: 13,
                    color: TemaApp.textoSecundario,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                PanelFiltros(
                  filtro: _filtro,
                  lugares: _lugares,
                  alCambiar: _cambiarFiltro,
                ),
                const SizedBox(height: 14),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_partidos.isEmpty && _filtro.estaActivo)
                  MensajeSinResultados(
                    alQuitarFiltros: () =>
                        _cambiarFiltro(const FiltroPartidos()),
                  )
                else if (_partidos.isEmpty)
                  _construirEstadoVacio()
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _partidos.length == 1
                          ? '1 partido encontrado'
                          : '${_partidos.length} partidos encontrados',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TemaApp.textoSecundario,
                      ),
                    ),
                  ),
                  ..._partidos.map(
                    (item) => TarjetaPartido(
                      partido: item.partido,
                      onUnirse: () => _unirse(item),
                    ),
                  ),
                ],
              ],
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
              color: TemaApp.azulSuave,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.compass,
              size: 28,
              color: TemaApp.azulDeportivo,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Todavía no hay partidos de otros estudiantes',
            textAlign: TextAlign.center,
            style: TemaApp.titulo(tamano: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cuando alguien cree un partido, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: TemaApp.textoSecundario),
          ),
        ],
      ),
    );
  }
}
