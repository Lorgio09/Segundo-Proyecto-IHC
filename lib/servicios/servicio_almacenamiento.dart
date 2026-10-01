import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/modelo_usuario.dart';

/// Servicio de persistencia local usando SharedPreferences
class ServicioAlmacenamiento {
  static const String _claveUsuario = 'unisport_usuario_sesion';
  static const String _claveUsuariosRegistrados = 'unisport_usuarios_registrados';

  // Guardar usuario con sesión activa
  Future<void> guardarSesion(ModeloUsuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUsuario, jsonEncode(usuario.toJson()));
  }

  // Obtener usuario con sesión activa
  Future<ModeloUsuario?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString(_claveUsuario);
    if (usuarioJson == null) return null;
    try {
      final mapa = jsonDecode(usuarioJson) as Map<String, dynamic>;
      return ModeloUsuario.fromJson(mapa);
    } catch (_) {
      return null;
    }
  }

  // Borrar sesión activa (Logout)
  Future<void> borrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUsuario);
  }

  // Guardar lista de usuarios registrados
  Future<void> guardarUsuarios(List<ModeloUsuario> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = usuarios.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_claveUsuariosRegistrados, listaJson);
  }

  // Obtener lista de usuarios registrados
  Future<List<ModeloUsuario>> obtenerUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(_claveUsuariosRegistrados);
    if (listaJson == null || listaJson.isEmpty) return [];

    return listaJson.map((str) {
      final mapa = jsonDecode(str) as Map<String, dynamic>;
      return ModeloUsuario.fromJson(mapa);
    }).toList();
  }
}
