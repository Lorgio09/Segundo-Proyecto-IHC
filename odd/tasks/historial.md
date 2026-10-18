# Feature: Historial de Participación en UniSport
# Tarea 4: Implementación y Decisiones de Interacción (Clase 16)
# Estado: En progreso

## Specs

S1. "El historial convierte acciones aisladas en una trayectoria visible." La persona necesita saber qué ocurrió, cuándo ocurrió, cuál fue el resultado y qué elemento estuvo involucrado.
S2. "UniSport: ¿En qué partidos participó la persona?" Consulta real asociada al usuario autenticado, ordenada con lo más reciente primero (ORDER BY fecha_inicio DESC o creado_en DESC), sin datos mockeados o hardcodeados.
S3. "Inicio en GitHub: Issue principal con historia de usuario y criterios de aceptación; sub-issues para datos, consulta, interfaz y pruebas; commits relacionados mediante #número; issue principal abierto hasta la revisión."
S4. "Resultado funcional: Una acción genera o conserva el evento; el usuario correcto consulta su historial; los datos permanecen después de recargar; existe un estado vacío y al menos una prueba."
S5. "Decisiones de diseño: Fitts (entrada al historial y acción frecuente fáciles de alcanzar); Hick (tipos de eventos o filtros sin competir en desorden); Carga cognitiva (cada evento muestra lo necesario y permite comprender sin recordar otras pantallas)."
S6. "Criterios de terminado: El issue y sus sub-issues explican el alcance; el historial usa datos reales y pertenece al usuario correcto; el orden y los estados se entienden; el estado vacío orienta qué hacer después; una prueba comprueba la consulta o regla principal; las tres decisiones tienen antes, después y código."

## Tasks

- [ ] T1 (S3): Crear el issue principal y los 4 sub-issues en GitHub con gh CLI.
- [ ] T2 (S1, S2): Diseñar el modelo y consulta de historial en Supabase y RepositorioPartidos.
- [ ] T3 (S4, S5): Diseñar la interfaz de Historial con empty state orientador y principios de interacción.
- [ ] T4 (S4, S6): Implementar pruebas unitarias y de widgets en Flutter para la consulta y el historial.
- [ ] T5 (S5, S6): Probar en la app real/emulador, capturar evidencias y documentar decisiones en docs/.
- [ ] T6 (S6): Verificación de extremo a extremo contra los 6 criterios de la rúbrica docente.

## Log

L1. El usuario solicitó realizar la Tarea 4 paso a paso con tiempo de sobra, cumpliendo estrictamente con lo requerido por las diapositivas de clase (sin hardcodear, con pruebas, capturas reales de pantalla y documentación).
