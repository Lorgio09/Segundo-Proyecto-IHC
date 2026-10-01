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
│   └── tema_app.dart               # Paleta de colores deportiva y bordes definidos
└── vistas/
    ├── vista_inicio_publico.dart   # Ruta Pública: Portada de UniSport
    ├── vista_login.dart            # Formulario de inicio de sesión con autollenado
    ├── vista_registro.dart         # Formulario de registro para nuevos estudiantes
    ├── vista_recuperar_clave.dart  # Recuperación simulada de contraseña
    └── vista_mis_partidos.dart     # Ruta Privada: Mis Partidos (Protegida)
```
