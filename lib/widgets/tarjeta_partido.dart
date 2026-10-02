import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../modelos/modelo_partido.dart';
import '../tema/iconos_deporte.dart';
import '../tema/tema_app.dart';

/// Tarjeta de un partido (se usa en Mis partidos y en la vista previa de Crear partido).
class TarjetaPartido extends StatelessWidget {
  final ModeloPartido partido;

  /// Si se entrega, el organizador ve el botón "Completar equipo"
  /// mientras el partido tenga los cupos abiertos.
  final VoidCallback? onCompletarEquipo;

  const TarjetaPartido({
    super.key,
    required this.partido,
    this.onCompletarEquipo,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = partido.cuposTotales == 0
        ? 0.0
        : (partido.cuposOcupados / partido.cuposTotales).clamp(0.0, 1.0);
    final colorEstado = partido.estaLleno
        ? TemaApp.verdeOscuro
        : TemaApp.naranjaAviso;
    final completo = partido.estado == EstadoPartido.equipoCompleto;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: TemaApp.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InsigniaDeporte(disciplina: partido.disciplina, tamano: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partido.titulo, style: TemaApp.titulo(tamano: 16)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: TemaApp.textoSecundario,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            partido.ubicacion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TemaApp.textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: TemaApp.textoSecundario,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            partido.fechaHora,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TemaApp.textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              completo
                  ? _etiquetaPequena(
                      partido.estado.etiqueta,
                      TemaApp.verdeSuave,
                      TemaApp.verdeOscuro,
                      LucideIcons.circleCheck,
                    )
                  : _etiquetaPequena(
                      partido.estado.etiqueta,
                      TemaApp.naranjaSuave,
                      const Color(0xFF9A3412),
                      LucideIcons.circleDot,
                    ),
              if (partido.soyOrganizador)
                _etiquetaPequena(
                  'Organizador',
                  TemaApp.azulSuave,
                  const Color(0xFF075985),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                LucideIcons.users,
                size: 16,
                color: TemaApp.textoSecundario,
              ),
              const SizedBox(width: 6),
              Text(
                '${partido.cuposOcupados}/${partido.cuposTotales}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: partido.estaLleno
                        ? TemaApp.verdeDeportivo
                        : TemaApp.naranjaAviso,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                partido.estaLleno
                    ? 'Completo'
                    : 'Faltan ${partido.cuposRestantes}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorEstado,
                ),
              ),
            ],
          ),
          // ACCIÓN: solo visible para el organizador mientras haya cupos abiertos
          if (onCompletarEquipo != null && partido.puedeCompletarEquipo) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onCompletarEquipo,
              icon: const Icon(LucideIcons.userCheck, size: 18),
              label: const Text('Completar equipo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _etiquetaPequena(
    String texto,
    Color fondo,
    Color color, [
    IconData? icono,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
