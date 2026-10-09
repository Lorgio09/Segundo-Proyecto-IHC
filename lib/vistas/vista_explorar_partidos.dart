import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../modelos/modelo_partido.dart';
import '../servicios/servicio_almacenamiento.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import '../widgets/tarjeta_partido.dart';

/// Explorar partidos organizados por otros estudiantes y unirse a ellos
/// (historia #1: "Como estudiante, quiero unirme a un partido con cupos abiertos").
class VistaExplorarPartidos extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaExplorarPartidos({super.key, required this.servicioAuth});

  @override
  State<VistaExplorarPartidos> createState() => _VistaExplorarPartidosState();
}

class _VistaExplorarPartidosState extends State<VistaExplorarPartidos> {
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();
  List<PartidoPublicado> _partidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final usuario = widget.servicioAuth.usuarioActual;
    if (usuario == null) return;

    final partidos = await _almacenamiento.obtenerPartidosParaExplorar(
      usuario.correo,
    );
    if (!mounted) return;
    setState(() {
      _partidos = partidos;
      _cargando = false;
    });
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
                const SizedBox(height: 16),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_partidos.isEmpty)
                  _construirEstadoVacio()
                else
                  ..._partidos.map(
                    (item) => TarjetaPartido(
                      partido: item.partido,
                      onUnirse: () => _unirse(item),
                    ),
                  ),
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
