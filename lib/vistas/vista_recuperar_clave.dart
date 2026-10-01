import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../tema/tema_app.dart';

/// Flujo de recuperación de contraseña simulado para pruebas de IHC
class VistaRecuperarClave extends StatefulWidget {
  final ServicioAutenticacion servicioAuth;

  const VistaRecuperarClave({
    super.key,
    required this.servicioAuth,
  });

  @override
  State<VistaRecuperarClave> createState() => _VistaRecuperarClaveState();
}

class _VistaRecuperarClaveState extends State<VistaRecuperarClave> {
  final _controladorCorreo = TextEditingController();
  bool _enviado = false;
  String? _mensajeError;
  bool _cargando = false;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  Future<void> _solicitarRecuperacion() async {
    final correo = _controladorCorreo.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _mensajeError = 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final error = await widget.servicioAuth.recuperarContrasena(correo);

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (error != null) {
        _mensajeError = error;
      } else {
        _enviado = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _enviado ? _construirVistaExito() : _construirFormulario(),
      ),
    );
  }

  Widget _construirFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: TemaApp.azulDeportivo),
        const SizedBox(height: 16),
        const Text(
          '¿Problemas para acceder?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: TemaApp.textoPrincipal),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tu correo institucional y te enviaremos las instrucciones de restablecimiento.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: TemaApp.textoSecundario),
        ),
        const SizedBox(height: 28),

        TextFormField(
          controller: _controladorCorreo,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Institucional',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),

        if (_mensajeError != null) ...[
          const SizedBox(height: 14),
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

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _cargando ? null : _solicitarRecuperacion,
          child: _cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('ENVIAR INSTRUCCIONES'),
        ),
      ],
    );
  }

  Widget _construirVistaExito() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TemaApp.verdeDeportivo, width: TemaApp.grosorBorde),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 60, color: TemaApp.verdeDeportivo),
              const SizedBox(height: 12),
              const Text(
                '¡Solicitud Procesada!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: TemaApp.textoPrincipal),
              ),
              const SizedBox(height: 8),
              Text(
                'Se enviaron las instrucciones a ${_controladorCorreo.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF166534), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  '💡 Simulación IHC: En producción este flujo se conecta al servicio SMTP. Para pruebas académicas se valida la existencia del usuario.',
                  style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('VOLVER AL INICIO DE SESIÓN'),
        ),
      ],
    );
  }
}
