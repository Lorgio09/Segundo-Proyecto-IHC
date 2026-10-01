import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import 'vista_login.dart';
import 'vista_mis_partidos.dart';

/// Formulario de registro simple para nuevos estudiantes universitarios
class VistaRegistro extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaRegistro({
    super.key,
    required this.servicioAuth,
  });

  @override
  State<VistaRegistro> createState() => _VistaRegistroState();
}

class _VistaRegistroState extends State<VistaRegistro> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorCarrera = TextEditingController();

  String _deporteSeleccionado = 'Futsal';
  bool _ocultarContrasena = true;
  bool _procesando = false;
  String? _mensajeError;

  final List<Map<String, String>> _deportes = [
    {'nombre': 'Futsal', 'icono': '⚽'},
    {'nombre': 'Básquetbol', 'icono': '🏀'},
    {'nombre': 'Voleibol', 'icono': '🏐'},
  ];

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorCarrera.dispose();
    super.dispose();
  }

  Future<void> _ejecutarRegistro() async {
    setState(() => _mensajeError = null);

    if (!_claveFormulario.currentState!.validate()) return;

    setState(() => _procesando = true);

    final error = await widget.servicioAuth.registrarUsuario(
      nombre: _controladorNombre.text,
      correo: _controladorCorreo.text,
      contrasena: _controladorContrasena.text,
      carrera: _controladorCarrera.text,
      deporteFavorito: _deporteSeleccionado,
    );

    if (!mounted) return;
    setState(() => _procesando = false);

    if (error != null) {
      setState(() => _mensajeError = error);
    } else {
      // Redirigir a la ruta privada protegida
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VistaMisPartidos(servicioAuth: widget.servicioAuth),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Estudiante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Únete a UniSport',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completa tus datos básicos para comenzar a jugar.',
                style: TextStyle(
                  fontSize: 14,
                  color: TemaApp.textoSecundario,
                ),
              ),

              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _controladorNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre y Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Correo
              TextFormField(
                controller: _controladorCorreo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Institucional (@uagrm.edu / @unisport.edu)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!valor.contains('@')) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Carrera
              TextFormField(
                controller: _controladorCarrera,
                decoration: const InputDecoration(
                  labelText: 'Carrera o Facultad',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _controladorContrasena,
                obscureText: _ocultarContrasena,
                decoration: InputDecoration(
                  labelText: 'Contraseña (mínimo 6 caracteres)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarContrasena ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Define una contraseña';
                  }
                  if (valor.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Deporte Favorito (Selector visual con chips de bordes anchos)
              const Text(
                'Deporte Principal:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _deportes.map((dep) {
                  final seleccionado = _deporteSeleccionado == dep['nombre'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _deporteSeleccionado = dep['nombre']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: seleccionado ? TemaApp.verdeDeportivo : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: TemaApp.borde,
                              width: seleccionado ? TemaApp.grosorBordeAncho : TemaApp.grosorBorde,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(dep['icono']!, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                dep['nombre']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: seleccionado ? Colors.white : TemaApp.textoPrincipal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_mensajeError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaApp.rojoAlerta, width: 2),
                  ),
                  child: Text(
                    _mensajeError!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              ElevatedButton(
                onPressed: _procesando ? null : _ejecutarRegistro,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('CREAR CUENTA E INGRESAR'),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta? ', style: TextStyle(color: TemaApp.textoSecundario)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VistaLogin(servicioAuth: widget.servicioAuth),
                        ),
                      );
                    },
                    child: const Text(
                      'Inicia sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: TemaApp.textoPrincipal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
