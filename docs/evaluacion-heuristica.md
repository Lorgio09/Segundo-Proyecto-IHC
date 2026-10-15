# Evaluación heurística H1–H10 · UniSport

**Issue principal:** #12 · **Flujo evaluado:** registrarse / iniciar sesión → Mis partidos → Crear partido → Explorar → buscar y filtrar → Unirme al equipo.
**Severidad (Nielsen):** 0 no es problema · 1 cosmético · 2 menor · 3 mayor · 4 catastrófico.

## Resumen

| H | Heurística | Estado | Sub-issue |
| :-: | :--- | :--- | :-: |
| H1 | Visibilidad del estado del sistema | Cumple | – |
| H2 | Relación con el mundo real | **Corregida** (búsqueda sin tildes) | #14 |
| H3 | Control y libertad | **Parcial**: ya pide confirmación y se puede cancelar; falta "Salir del partido" | #13 |
| H4 | Consistencia y estándares | Cumple | – |
| H5 | Prevención de errores | **Corregida** (confirmación antes de unirse) | #13 |
| H6 | Reconocer antes que recordar | **Corregida** (commit 28aa6b1) | – |
| H7 | Flexibilidad y eficiencia | **Corregida** (el filtro se conserva) | #15 |
| H8 | Diseño estético y minimalista | Cumple | – |
| H9 | Reconocer y recuperarse de errores | Cumple | – |
| H10 | Ayuda y documentación | **Corregida** (ayuda en Crear partido) | #16 |

> Estado de entrega: **#14 (H2) y #16 (H10) ya están corregidos en código** (commit a59b50d, con prueba nueva para H2). **#15 (H7) corregido** (a9f9edb) y **#13 corregido a medias**: ya hay confirmación al unirse (H5 corregida), pero **falta "Salir del partido"**, así que H3 sigue pendiente. Las capturas marcadas *(pendiente)* no se tomaron todavía; lo único capturado de la app corriendo es [h4-portada.png](evidencias/h4-portada.png).

## Detalle por heurística

### H1 · Visibilidad del estado del sistema — Cumple
- **Dónde:** Explorar → Unirme al equipo; Crear/Editar partido; botones de Login y Registro.
- **Cómo se comprobó:** tras unirse aparece "¡Te uniste a "…"! (n/N)" y, si corresponde, "El equipo quedó completo"; la tarjeta muestra la etiqueta *Cupos abiertos / Equipo completo* y la barra de cupos. Los botones pasan por texto → spinner → check.
- **Código:** `lib/vistas/vista_explorar_partidos.dart` (`_unirse`, `_avisar`), `lib/widgets/boton_accion.dart`, `lib/widgets/tarjeta_partido.dart`.
- **Captura:** *(pendiente)*

### H2 · Relación con el mundo real — No cumple (sev. 3) → #14
- **Dónde:** Explorar → buscar `voley`.
- **Problema:** se compara con tildes; "voley" no encuentra "Vóley…" y aparece "Ningún partido coincide con tu búsqueda". Consecuencia: la persona cree que no hay partidos.
- **Código:** `lib/modelos/filtro_partidos.dart` (`coincide`, `condicionesConsulta`), `lib/servicios/repositorio_supabase.dart` (`buscarPartidos`).
- **Captura (antes):** [hallazgo-3-busqueda-voley.png](evidencias/hallazgo-3-busqueda-voley.png)
- **Corrección:** `FiltroPartidos.normalizar` / `coincideTitulo` comparan sin tildes y el repositorio filtra el nombre en la app; prueba `test/filtro_partidos_test.dart` («la búsqueda por nombre ignora tildes y mayúsculas»). Captura después: *(pendiente)*

### H3 · Control y libertad — Parcial (pendiente "Salir del partido") → #13
- **Hecho:** se puede cancelar la unión en el diálogo de confirmación.
- **Falta:** acción "Salir del partido" (requiere una función nueva en el servidor de Supabase).
- **Dónde:** Explorar → Unirme al equipo.
- **Problema:** no existe "Salir del partido"; si se une por error ocupa un cupo ajeno. (Sí cumple en otros flujos: eliminar pide confirmación y editar se puede cancelar.)
- **Código:** `lib/widgets/tarjeta_partido.dart`, `lib/vistas/vista_explorar_partidos.dart`.
- **Captura:** [hallazgo-2-unirse-sin-salida.png](evidencias/hallazgo-2-unirse-sin-salida.png)

### H4 · Consistencia y estándares — Cumple
- **Dónde:** barra inferior de la portada y de Mis partidos (`Explorar | Mis partidos`, mismo orden); la acción de unirse se llama "Unirme al equipo" en todas las pantallas.
- **Código:** `lib/vistas/vista_inicio_publico.dart`, `lib/vistas/vista_mis_partidos.dart`, `test/navegacion_explorar_test.dart`.
- **Captura:** [hallazgo-1-despues.png](evidencias/hallazgo-1-despues.png)
- **Observación (sev. 1, no bloqueante):** el registro ofrece 3 deportes y Crear partido 6.

### H5 · Prevención de errores — Corregida → #13
- **Corrección:** diálogo «¿Unirte al equipo?» con Cancelar / Sí, unirme en `lib/vistas/vista_explorar_partidos.dart`; pruebas en `test/explorar_filtros_test.dart`.
- **Sí cumple:** Agregar jugador se apaga con el equipo completo y explica el motivo; el servidor vuelve a validar las reglas.
- **Problema:** unirse no pide confirmación, así que un toque accidental ocupa un cupo.
- **Código:** `lib/modelos/modelo_partido.dart` (`puedeUnirse`), `lib/vistas/vista_explorar_partidos.dart`.

### H6 · Reconocer antes que recordar — Corregida
- **Antes:** "Explorar" solo dentro de Mis partidos. **Después:** pestaña Explorar en la barra inferior.
- **Archivos:** `lib/vistas/vista_inicio_publico.dart`, `lib/vistas/vista_mis_partidos.dart`, `test/navegacion_explorar_test.dart` (commit 28aa6b1).
- **Capturas:** [antes](evidencias/hallazgo-1-mis-partidos.png) · [después](evidencias/hallazgo-1-despues.png)

### H7 · Flexibilidad y eficiencia — Corregida → #15
- **Corrección:** el filtro se guarda en `ServicioAutenticacion.filtroExplorar` y se reinicia al cerrar sesión; prueba `test/explorar_filtros_test.dart` («H7: el filtro se conserva…»).
- **Problema:** el filtro vive en el estado de `VistaExplorarPartidos`; al salir y volver se reinicia.
- **Código:** `lib/vistas/vista_explorar_partidos.dart` (`_filtro`).
- **Captura:** *(pendiente)*

### H8 · Diseño estético y minimalista — Cumple
- **Cómo se comprobó:** cada tarjeta destaca una acción principal ("Unirme al equipo" o las del organizador) con el botón de color primario; las acciones secundarias son íconos pequeños.
- **Código:** `lib/widgets/tarjeta_partido.dart`, `lib/tema/tema_app.dart`.
- **Captura:** *(pendiente)*

### H9 · Reconocer y recuperarse de errores — Cumple
- **Cómo se comprobó:** los rechazos explican el motivo con lenguaje claro: "No puedes unirte. Convocatoria cerrada: el equipo ya está completo.", "El partido ya se jugó…", "Ya formas parte de este equipo."; sin conexión se muestra un mensaje propio.
- **Código:** `lib/modelos/modelo_partido.dart` (`motivoRechazoUnirse`), `lib/widgets/tarjeta_partido.dart`, `test/tarjeta_partido_test.dart`.
- **Captura:** *(pendiente)*

### H10 · Ayuda y documentación — Corregida → #16
- **Problema:** no había texto de ayuda junto a los cupos ni a "Completar equipo" / "Agregar jugador".
- **Corrección:** texto breve bajo el selector de cupos en `lib/vistas/vista_crear_partido.dart`.
- **Código:** `lib/vistas/vista_crear_partido.dart`, `lib/widgets/tarjeta_partido.dart`.
- **Captura:** *(pendiente)*
