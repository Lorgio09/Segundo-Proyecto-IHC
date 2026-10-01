import 'package:flutter/foundation.dart';
import '../modelos/modelo_usuario.dart';
import 'servicio_almacenamiento.dart';

/// Servicio central de autenticación con datos semilla y persistencia
class ServicioAutenticacion extends ChangeNotifier {
  final ServicioAlmacenamiento _almacenamiento = ServicioAlmacenamiento();

  ModeloUsuario? _usuarioActual;
  bool _estaCargando = true;

  ModeloUsuario? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _usuarioActual != null;
  bool get estaCargando => _estaCargando;

  // Cuentas semilla iniciales para pruebas del docente
  static final List<ModeloUsuario> _usuariosSemilla = [
    ModeloUsuario(
      id: 'usr-001',
      nombre: 'Diego Astete Paz',
      correo: 'diego@unisport.edu',
      contrasena: '123456',
      carrera: 'Ingeniería en Sistemas',
      deporteFavorito: 'Futsal',
    ),
    ModeloUsuario(
      id: 'usr-002',
      nombre: 'Lorgio Leonardo Choque Severiche',
      correo: 'lorgio@unisport.edu',
      contrasena: '123456',
      carrera: 'Ingeniería en Sistemas',
      deporteFavorito: 'Básquetbol',
    ),
  ];

  List<ModeloUsuario> _usuarios = [];

  // Inicializar servicio y verificar si existía sesión previa
  Future<void> inicializar() async {
    _estaCargando = true;
    notifyListeners();

    // Cargar usuarios guardados o inicializar con semillas
    final guardados = await _almacenamiento.obtenerUsuarios();
    if (guardados.isEmpty) {
      _usuarios = List.from(_usuariosSemilla);
      await _almacenamiento.guardarUsuarios(_usuarios);
    } else {
      _usuarios = guardados;
      // Asegurar que las semillas siempre estén presentes
      for (final semilla in _usuariosSemilla) {
        if (!_usuarios.any((u) => u.correo.toLowerCase() == semilla.correo.toLowerCase())) {
          _usuarios.add(semilla);
        }
      }
      await _almacenamiento.guardarUsuarios(_usuarios);
    }

    // Verificar si hay sesión previa guardada
    _usuarioActual = await _almacenamiento.obtenerSesion();
    _estaCargando = false;
    notifyListeners();
  }

  // Iniciar sesión
  Future<String?> iniciarSesion(String correo, String contrasena) async {
    final correoLimpio = correo.trim().toLowerCase();
    final passLimpia = contrasena.trim();

    final encontrado = _usuarios.firstWhere(
      (u) => u.correo.toLowerCase() == correoLimpio && u.contrasena == passLimpia,
      orElse: () => ModeloUsuario(id: '', nombre: '', correo: '', contrasena: ''),
    );

    if (encontrado.id.isEmpty) {
      return 'Correo o contraseña incorrectos. Verifica tus credenciales.';
    }

    _usuarioActual = encontrado;
    await _almacenamiento.guardarSesion(encontrado);
    notifyListeners();
    return null; // Sin errores = éxito
  }

  // Registrar un nuevo estudiante
  Future<String?> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String carrera,
    required String deporteFavorito,
  }) async {
    final correoLimpio = correo.trim().toLowerCase();
    
    if (_usuarios.any((u) => u.correo.toLowerCase() == correoLimpio)) {
      return 'Este correo ya se encuentra registrado.';
    }

    final nuevoUsuario = ModeloUsuario(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre.trim(),
      correo: correoLimpio,
      contrasena: contrasena.trim(),
      carrera: carrera.trim().isEmpty ? 'Ingeniería' : carrera.trim(),
      deporteFavorito: deporteFavorito,
    );

    _usuarios.add(nuevoUsuario);
    await _almacenamiento.guardarUsuarios(_usuarios);

    // Iniciar sesión automáticamente tras el registro
    _usuarioActual = nuevoUsuario;
    await _almacenamiento.guardarSesion(nuevoUsuario);
    notifyListeners();
    return null;
  }

  // Recuperar contraseña (simulado)
  Future<String?> recuperarContrasena(String correo) async {
    final correoLimpio = correo.trim().toLowerCase();
    final existe = _usuarios.any((u) => u.correo.toLowerCase() == correoLimpio);

    if (!existe) {
      return 'No encontramos ninguna cuenta con ese correo.';
    }

    // En un sistema real se envía correo. Aquí se simula exitosamente.
    return null;
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    _usuarioActual = null;
    await _almacenamiento.borrarSesion();
    notifyListeners();
  }
}
