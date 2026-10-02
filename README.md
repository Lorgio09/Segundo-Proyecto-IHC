# UniSport ⚽🏀🏐 - Proyecto 2 IHC

> **Materia:** Interacción Humano-Computador (Clase 12 / Proyecto 2)  
> **Modalidad P2:** Con IA  
> **Integrantes:**  
> - Diego Astete Paz  
> - Lorgio Leonardo Choque Severiche  
> **Tecnología:** Flutter (Dart) - Móvil & Web

---

## 📌 Propósito del Producto
**UniSport** es una aplicación diseñada para resolver la fricción de coordinar encuentros deportivos en el campus universitario:
- **Crear partidos** definiendo disciplina (Futsal, Básquetbol, Vóley), cancha y horario.
- **Completar equipos** permitiendo que estudiantes se unan a convocatorias abiertas con cupos disponibles.

---

## 🚀 Guía de Ejecución

### 1. Requisitos Previos
* Flutter SDK (3.x o superior) instalado y configurado en el sistema (Windows, macOS o Linux).
* Emulador Android / iOS, dispositivo móvil conectado, o navegador Web (Chrome / Edge).

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Ejecutar la aplicación
Ejecutar el comando estándar (Flutter detectará automáticamente el dispositivo o emulador disponible):
```bash
flutter run
```

*Si se desea especificar una plataforma concreta:*
* **En Navegador Web:**
  ```bash
  flutter run -d chrome
  ```
* **En Emulador o Teléfono Móvil:**
  ```bash
  flutter run -d android
  ```
* **En Escritorio (Windows / macOS / Linux):**
  ```bash
  flutter run -d windows    # En Windows
  flutter run -d macos      # En macOS
  flutter run -d linux      # En Linux
  ```

### 4. Ejecutar pruebas automatizadas
```bash
flutter test
```

Solo las pruebas unitarias de la Tarea 2 (cambio de estado del partido):
```bash
flutter test test/estado_partido_test.dart
```
Detalle de la tarea y de las pruebas en [`docs/task-02-state-tests.md`](docs/task-02-state-tests.md).

---

## ⚡ Cuentas Semilla para Pruebas (Seeds)

La aplicación incluye cuentas precargadas en el servicio de autenticación listas para iniciar sesión directamente:

| Estudiante | Correo | Contraseña | Carrera | Deporte |
| :--- | :--- | :--- | :--- | :--- |
| **Diego Astete** | `diego@unisport.edu` | `123456` | Ingeniería en Sistemas | Futsal |
| **Lorgio Choque** | `lorgio@unisport.edu` | `123456` | Ingeniería en Sistemas | Básquetbol |

*También es posible crear nuevas cuentas en el formulario de **Registro** con cualquier correo institucional.*

---

## 🛡️ Verificación de Requisitos (Tarea 1 - Acceso y Rutas Protegidas)

1. **Ruta Pública (Bienvenida):**  
   Al abrir la aplicación sin sesión, se muestra la portada de UniSport con su propuesta de valor, disciplinas y accesos para iniciar sesión o registrarse.

2. **Ruta Privada Protegida ("Mis Partidos"):**  
   - Si un usuario sin autenticación intenta abrir `"Mis Partidos"` (o pulsa el botón de prueba en la portada), el sistema **bloquea el acceso y lo redirige automáticamente al Login** con un mensaje de alerta.
   - Una vez autenticado, la pantalla muestra en la cabecera el **nombre del estudiante logueado**, su correo y su estado activo, junto con sus partidos programados y filtros por rol (Organizador / Jugador).

3. **Persistencia de Sesión:**  
   Se utiliza almacenamiento local (`shared_preferences`). Si cierras la aplicación o la recargas, la sesión se conserva activa y abre directamente en *"Mis Partidos"*.

4. **Recuperación de Contraseña Simulada:**  
   Flujo con retroalimentación visual inmediata (Heurística de Visibilidad de Estado de Nielsen) validando la existencia de la cuenta.

5. **Cierre de Sesión (Logout):**  
   Limpia el almacenamiento local de sesión y regresa al estado público como invitado.

---

## ✅ Tarea 2 - Cambio de estado y pruebas unitarias

- **Nueva acción:** en *Mis partidos*, el organizador pulsa **Completar equipo** y el partido pasa de **Cupos abiertos** a **Equipo completo** (los cupos quedan completos).
- **Persistencia:** el cambio se guarda y se conserva al recargar la aplicación.
- **Pruebas unitarias:** 8 pruebas sobre la regla de cambio de estado, ejecutadas y aprobadas con `flutter test`.
- **Documentación:** [`docs/task-02-state-tests.md`](docs/task-02-state-tests.md)

---

## 📁 Estructura del Código (En Español)

```
lib/
├── main.dart                       # Entrada y enrutamiento con verificación de sesión
├── modelos/
│   ├── modelo_usuario.dart         # Modelo de datos de estudiante
│   └── modelo_partido.dart         # Modelo de datos de partido y cupos
├── servicios/
│   ├── servicio_autenticacion.dart # Lógica de login, registro, logout y semillas
│   └── servicio_almacenamiento.dart# Persistencia local con SharedPreferences
├── tema/
│   ├── tema_app.dart               # Tema claro: paleta verde/cian, tipografía y componentes
│   ├── iconos_deporte.dart         # Ícono y color de cada disciplina
│   └── caja_mensaje.dart           # Avisos de error / información / éxito
├── widgets/
│   ├── tarjeta_partido.dart        # Tarjeta de partido con la acción "Completar equipo"
│   ├── campo_clave.dart            # Campo de contraseña con balones animados
│   ├── boton_accion.dart           # Botón con estados (normal / cargando / éxito)
│   └── animaciones.dart            # Entrada escalonada y sacudida de formulario
└── vistas/
    ├── vista_inicio_publico.dart   # Ruta Pública: Portada de UniSport
    ├── vista_login.dart            # Formulario de inicio de sesión con autollenado
    ├── vista_registro.dart         # Formulario de registro para nuevos estudiantes
    ├── vista_recuperar_clave.dart  # Recuperación simulada de contraseña
    ├── vista_mis_partidos.dart     # Ruta Privada: Mis Partidos (Protegida)
    └── vista_crear_partido.dart    # Formulario para crear un partido

test/
├── estado_partido_test.dart        # Pruebas unitarias del cambio de estado (Tarea 2)
└── widget_test.dart                # Prueba de la portada pública
```
