# Feature: Historial de Participación en UniSport
# Tarea 4: Implementación y Decisiones de Interacción (Clase 16)
# Estado: Completado (Verificado contra Rúbrica)

## Specs

S1. "El historial convierte acciones aisladas en una trayectoria visible." La persona necesita saber qué ocurrió, cuándo ocurrió, cuál fue el resultado y qué elemento estuvo involucrado.
S2. "UniSport: ¿En qué partidos participó la persona?" Consulta real asociada al usuario autenticado, ordenada con lo más reciente primero (ORDER BY fecha_inicio DESC o creado_en DESC), sin datos mockeados o hardcodeados.
S3. "Inicio en GitHub: Issue principal con historia de usuario y criterios de aceptación; sub-issues para datos, consulta, interfaz y pruebas; commits relacionados mediante #número; issue principal abierto hasta la revisión."
S4. "Resultado funcional: Una acción genera o conserva el evento; el usuario correcto consulta su historial; los datos permanecen después de recargar; existe un estado vacío y al menos una prueba."
S5. "Decisiones de diseño: Fitts (entrada al historial y acción frecuente fáciles de alcanzar); Hick (tipos de eventos o filtros sin competir en desorden); Carga cognitiva (cada evento muestra lo necesario y permite comprender sin recordar otras pantallas)."
S6. "Criterios de terminado: El issue y sus sub-issues explican el alcance; el historial usa datos reales y pertenece al usuario correcto; el orden y los estados se entienden; el estado vacío orienta qué hacer después; una prueba comprueba la consulta o regla principal; las tres decisiones tienen antes, después y código."

## Tasks

- [x] T1 (S3): Crear el issue principal (#17) y los 4 sub-issues (#18, #19, #20, #21) en GitHub con gh CLI. Commit: `3997ece`.
- [x] T2 (S1, S2): Diseñar el modelo y consulta de historial en Supabase y RepositorioPartidos. Commit: `3997ece`.
- [x] T3 (S4, S5): Diseñar la interfaz de Historial con empty state orientador y principios de interacción. Commit: `0a5567d`.
- [x] T4 (S4, S6): Implementar pruebas unitarias y de widgets en Flutter para la consulta y el historial (7 tests). Commit: `0a5567d`.
- [x] T5 (S5, S6): Probar en la app real/emulador, capturar evidencias (1080x2400) y documentar decisiones en docs/. Commit: `8a9c514`.
- [x] T6 (S6): Verificación de extremo a extremo contra los 6 criterios de la rúbrica docente. Issue #17 abierto; suite completa con 97 tests pasando.

## Log

L1. El usuario solicitó realizar la Tarea 4 paso a paso con tiempo de sobra, cumpliendo estrictamente con lo requerido por las diapositivas de clase (sin hardcodear, con pruebas, capturas reales de pantalla y documentación).
L2. Se implementó el modelo EventoHistorial y la consulta en Supabase/RPC y RepositorioPartidos.
L3. Se diseñaron las vistas VistaHistorial, TarjetaHistorial y el punto de acceso en VistaMisPartidos aplicando Fitts, Hick y Carga Cognitiva.
L4. Se agregaron 7 pruebas unitarias y de widgets en test/historial_test.dart. Toda la suite (97 tests) pasa al 100%.
L5. Se lanzaron sesiones en el emulador Android Pixel 6 y se capturaron las 4 imágenes nativas para Fitts, Hick, Carga Cognitiva y Empty State.
L6. Se actualizó docs/clase-16-decisiones-interaccion.md y se pushearon todos los cambios a origin/main.
