import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';
import 'vista_registro.dart';
import 'vista_recuperar_clave.dart';
import 'vista_mis_partidos.dart';

/// Formulario de inicio de sesión con soporte para pruebas rápidas
class VistaLogin extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;
  final String? mensajeRedireccion;

  const VistaLogin({
    super.key,
    required this.servicioAuth,
    this.mensajeRedireccion,
  });

  @override
  State<VistaLogin> createState() => _VistaLoginState();
}

class _VistaLoginState extends State<VistaLogin> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();

  bool _ocultarContrasena = true;
  bool _procesando = false;
  String? _mensajeError;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _ejecutarLogin() async {
    setState(() => _mensajeError = null);

    if (!_claveFormulario.currentState!.validate()) return;

    setState(() => _procesando = true);

    final error = await widget.servicioAuth.iniciarSesion(
      _controladorCorreo.text,
      _controladorContrasena.text,
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

  void _autollenar(String correo, String contrasena) {
    _controladorCorreo.text = correo;
    _controladorContrasena.text = contrasena;
    setState(() => _mensajeError = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alerta si fue redirigido por protección de ruta
              if (widget.mensajeRedireccion != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TemaApp.rojoAlerta, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gpp_bad, color: TemaApp.rojoAlerta),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.mensajeRedireccion!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Título y Subtítulo
              const Text(
                'Bienvenido de vuelta',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ingresa tus credenciales para acceder a tus partidos.',
                style: TextStyle(
                  fontSize: 14,
                  color: TemaApp.textoSecundario,
                ),
              ),

              const SizedBox(height: 28),

              // Botones de Autollenado Rápido para el Docente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Cuentas de Prueba (1 toque):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TemaApp.textoPrincipal),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Text('⚽'),
                          label: const Text('Diego Astete', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => _autollenar('diego@unisport.edu', '123456'),
                        ),
                        ActionChip(
                          avatar: const Text('🏀'),
                          label: const Text('Lorgio Choque', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => _autollenar('lorgio@unisport.edu', '123456'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Campo Correo
              TextFormField(
                controller: _controladorCorreo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Institucional / Estudiantil',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa tu correo institucional';
                  }
                  if (!valor.contains('@')) {
                    return 'Formato de correo no válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Campo Contraseña
              TextFormField(
                controller: _controladorContrasena,
                obscureText: _ocultarContrasena,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarContrasena ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (valor.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Enlace Olvidé mi Contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VistaRecuperarClave(servicioAuth: widget.servicioAuth),
                      ),
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: TemaApp.azulDeportivo,
                    ),
                  ),
                ),
              ),

              // Mensaje de Error si las credenciales fallan
              if (_mensajeError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaApp.rojoAlerta, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: TemaApp.rojoAlerta, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensajeError!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón Entrar
              ElevatedButton(
                onPressed: _procesando ? null : _ejecutarLogin,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('ENTRAR A UNISPORT'),
              ),

              const SizedBox(height: 20),

              // Enlace Registrarse
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Aún no tienes cuenta? ', style: TextStyle(color: TemaApp.textoSecundario)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VistaRegistro(servicioAuth: widget.servicioAuth),
                        ),
                      );
                    },
                    child: const Text(
                      'Regístrate aquí',
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
