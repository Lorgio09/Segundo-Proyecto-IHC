# Tarea 2 · Cambio de estado y pruebas unitarias

**Proyecto:** UniSport · **Elemento:** Partido · **Entrega:** 6 de octubre de 2026, antes de la clase

## Parte 1 · Nueva funcionalidad

**Cupos abiertos → Equipo completo**, mediante la acción **"Completar equipo"**.

| Qué | Detalle |
| :--- | :--- |
| Estado inicial | `Cupos abiertos` (todo partido nuevo nace así) |
| Acción | Botón **Completar equipo** en la tarjeta del partido (pantalla *Mis partidos*) |
| Estado resultante | `Equipo completo` |
| Efecto adicional | Los cupos ocupados pasan a ser iguales al total (por ejemplo `3/10` → `10/10`) |
| Persistencia | El cambio se guarda con `shared_preferences` y se conserva al recargar o reiniciar la app |

### Regla de cambio de estado

Implementada en [`lib/modelos/modelo_partido.dart`](../lib/modelos/modelo_partido.dart), sin depender de la interfaz:

1. Solo el **organizador** del partido puede completar el equipo.
2. Solo se puede completar si el partido está en `Cupos abiertos`.
3. `Equipo completo` es un estado final: la acción no se puede repetir ni deshacer.
4. La acción devuelve una **copia** del partido; el objeto original no se modifica.

```dart
partido.puedeCompletarEquipo;      // ¿está permitida la acción ahora mismo?
partido.completarEquipo();         // devuelve el partido ya completo (o lanza StateError)
```

### Cómo verlo funcionando en la interfaz

1. Iniciar sesión (por ejemplo `lorgio@unisport.edu` / `123456`).
2. En *Mis partidos* pulsar **Crear partido** y guardar uno nuevo: aparece con la etiqueta *Cupos abiertos*.
3. Pulsar **Completar equipo** en su tarjeta: la etiqueta cambia a *Equipo completo*, los cupos quedan completos y el botón desaparece.
4. Recargar la página o reiniciar la app: el partido sigue como *Equipo completo*.

## Parte 2 · Pruebas unitarias

Archivo: [`test/estado_partido_test.dart`](../test/estado_partido_test.dart)

### Comando

```bash
flutter test
```

Solo las pruebas de esta tarea:

```bash
flutter test test/estado_partido_test.dart
```

### Pruebas incluidas (8)

| # | Prueba | Qué comprueba |
| :-: | :--- | :--- |
| 1 | Un partido nuevo nace con los cupos abiertos | Estado inicial y acción disponible |
| 2 | El organizador pasa el partido de *Cupos abiertos* a *Equipo completo* | El cambio de estado |
| 3 | Al completar el equipo todos los cupos quedan ocupados | `cuposOcupados == cuposTotales`, sin cupos restantes |
| 4 | No se puede completar un equipo que ya está completo | Estado final: lanza `StateError` |
| 5 | Quien no es organizador no puede completar el equipo | Restricción por rol |
| 6 | Completar el equipo no modifica el partido original | Inmutabilidad |
| 7 | El estado *Equipo completo* se guarda y se recupera | Persistencia (guardar y leer con un servicio nuevo) |
| 8 | Un partido guardado sin estado se recupera con cupos abiertos | Compatibilidad con datos guardados antes de esta tarea |

### Resultado de la ejecución

```
00:07 +9: All tests passed!
```

Son las 8 pruebas de esta tarea más la prueba de la portada pública que ya existía (`test/widget_test.dart`), actualizada a los textos del nuevo diseño.

## Archivos de la tarea

| Archivo | Rol |
| :--- | :--- |
| `lib/modelos/modelo_partido.dart` | Estado `EstadoPartido` y regla `completarEquipo()` |
| `lib/widgets/tarjeta_partido.dart` | Botón *Completar equipo* y etiqueta de estado |
| `lib/vistas/vista_mis_partidos.dart` | Ejecuta la acción y guarda el resultado |
| `test/estado_partido_test.dart` | Pruebas unitarias |
| `docs/task-02-state-tests.md` | Este documento |
