# Tarea 3 · Ciclo del elemento y restricción de estado

**Proyecto:** UniSport · **Elemento:** Partido · **Fecha:** 7 de octubre de 2026

---

## 1. Funcionalidades implementadas

### A. Editar datos del partido
* **Ubicación:** Botón de edición (ícono de lápiz) en la tarjeta del partido para el organizador.
* **Comportamiento:** Abre el formulario pre-cargado con los datos del partido (`VistaCrearPartido`), permitiendo modificar título, deporte, ubicación, fecha/hora y cupos totales.
* **Consistencia:** No permite reducir los cupos totales por debajo de los jugadores que ya están inscritos.
* **Persistencia:** Al guardar los cambios, se actualiza en memoria y se persiste automáticamente en la base de datos SQLite.

### B. Eliminar el partido solicitando confirmación
* **Ubicación:** Botón de eliminar (ícono de papelera) en la tarjeta del partido para el organizador.
* **Comportamiento:** Abre un cuadro de diálogo modal (`AlertDialog`) solicitando confirmación explícita (*"¿Estás seguro de que deseas eliminar [Título]? Esta acción no se puede deshacer"*).
* **Persistencia:** Si se confirma, el partido se remueve de la lista del usuario y se elimina de la base de datos SQLite.

### C. Restricción según su estado: "Un equipo completo no permite agregar más jugadores"
* **Regla de negocio:** Un partido en estado `Equipo completo` (o con todos sus cupos ocupados) bloquea la incorporación de nuevos jugadores.
* **Explicación clara en la UI:**
  * Cuando la acción está bloqueada, la interfaz muestra un aviso visible:
    > **No puedes unirte:** Convocatoria cerrada: el equipo ya está completo.
  * Si el equipo aún tiene cupos abiertos, se muestra el botón interactivo **"Unirme al equipo"** que suma un jugador y actualiza la barra de progreso.
* **Acción visible para el organizador: "Agregar jugador".** Con cupos abiertos suma un jugador (por ejemplo 3/10 → 4/10) y se guarda en la base de datos. Al ocupar el último cupo, el partido pasa solo a *Equipo completo*.
* **Cómo se ve el bloqueo:** cuando el equipo está completo, el botón "Agregar jugador" aparece apagado con un ícono de prohibido, y debajo se muestra siempre este aviso:
  > **No puedes agregar más jugadores.** Convocatoria cerrada: el equipo ya está completo.

  Si se toca el botón apagado, además aparece un mensaje con el mismo motivo.
* **Arquitectura:** La restricción está protegida en [`lib/modelos/modelo_partido.dart`](../lib/modelos/modelo_partido.dart) mediante el método inmutable `agregarJugador()`, que lanza un `StateError` descriptivo si se intenta violar la regla fuera de la interfaz.

### D. Base de datos SQLite
* **Tecnología:** `sqflite` (SQLite), la base de datos nativa de Android e iOS. El archivo se llama `unisport.db`.
* **Tabla `partidos`:** una fila por partido con sus datos (título, disciplina, ubicación, fecha y hora, cupos totales y ocupados, estado, organizador, etc.). La clave primaria es `(correo_usuario, id)`, por lo que cada estudiante solo ve sus propios partidos.
* **Operaciones:** crear, editar, eliminar y cambiar de estado se guardan en una transacción de SQLite; al reabrir la app se leen de la base de datos.
* **Migración:** si un usuario tenía partidos guardados con la versión anterior (`SharedPreferences`), se pasan automáticamente a SQLite la primera vez que abre *Mis partidos*.
* **Nota sobre web:** `sqflite` no existe en el navegador, así que al ejecutar en Chrome se usa `SharedPreferences` como respaldo para poder desarrollar. La entrega y la demostración están pensadas para **móvil** (Android / iOS).
* **Sesión y usuarios registrados** siguen en `SharedPreferences`; la información de los partidos (el elemento de la tarea) está en la base de datos.
* **Código:** [`lib/servicios/servicio_almacenamiento.dart`](../lib/servicios/servicio_almacenamiento.dart)

---

## 2. Pruebas unitarias

Archivo: [`test/restriccion_partido_test.dart`](../test/restriccion_partido_test.dart)

### Comando para ejecutar

```bash
flutter test test/restriccion_partido_test.dart
```

Pruebas de la base de datos SQLite (crear, editar, eliminar, aislamiento por usuario y migración):

```bash
flutter test test/almacenamiento_sqlite_test.dart
```

Pruebas de interfaz de la restricción (botón y mensaje de bloqueo):

```bash
flutter test test/tarjeta_partido_test.dart
```

Para correr todas las pruebas del proyecto (21 pruebas aprobadas):

```bash
flutter test
```

### Casos de prueba incluidos (5)

1. Un partido con cupos abiertos permite agregar jugadores e incrementa `cuposOcupados`.
2. Restricción: un partido en estado `Equipo completo` tiene `puedeAgregarJugador == false`.
3. La propiedad `motivoBloqueoAgregarJugador` explica con precisión el motivo del bloqueo.
4. Invocar `agregarJugador()` sobre un partido completo lanza `StateError` impidiendo la mutación inválida.
5. Al llenar el último cupo disponible, la transición a `Equipo completo` se efectúa automáticamente y bloquea nuevas adhesiones.

---

## 3. Archivos modificados y creados

| Archivo | Rol |
| :--- | :--- |
| `lib/modelos/modelo_partido.dart` | Inmutabilidad (`copyWith`), regla de restricción `puedeAgregarJugador`, motivo y método `agregarJugador()` |
| `lib/vistas/vista_crear_partido.dart` | Soporte para modo edición (`partidoAEditar`) y validación de cupos mínimos |
| `lib/vistas/vista_mis_partidos.dart` | Flujos de edición, diálogo modal de confirmación de eliminación y acción de unirse |
| `lib/widgets/tarjeta_partido.dart` | Botones de edición/eliminación para organizador y feedback visual del bloqueo |
| `lib/servicios/servicio_almacenamiento.dart` | Base de datos SQLite (tabla `partidos`), transacciones y migración desde SharedPreferences |
| `test/almacenamiento_sqlite_test.dart` | 5 pruebas de la base de datos: guardar, editar, eliminar, aislamiento por usuario y migración |
| `test/tarjeta_partido_test.dart` | 2 pruebas de interfaz: botón "Agregar jugador" con cupos abiertos y aviso del motivo cuando el equipo está completo |
| `test/restriccion_partido_test.dart` | 5 pruebas unitarias automatizadas para la restricción de UniSport |
| `docs/task-03-lifecycle-restriction.md` | Este documento de respaldo |
