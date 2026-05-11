import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/polired_logo.dart';
import '../../widgets/primary_button.dart';

/// Register Screen — reinterpretación del HTML de referencia.
/// Campos: nombre, apellido, correo, contraseña, confirmar contraseña.
/// El username se solicita en una pantalla posterior (primera vez tras login).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      nombre: _nombreCtrl.text,
      apellido: _apellidoCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSuccessDialog(
          result.message ?? 'Revisa tu correo para confirmar tu cuenta');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Error al registrar')),
      );
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppTheme.success, size: 40),
        title: Text('¡Registro exitoso!',
            style: AppTheme.headlineMedium, textAlign: TextAlign.center),
        content: Text(message,
            style: AppTheme.bodyMedium, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text(
              'Ir al inicio de sesión',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo ligeramente gris como en el HTML (canvas-bg: #f9f9f9)
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  children: [
                    // ── Tarjeta principal (card blanca) ─────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.1),
                        ),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // Logo
                          const PoliredLogo(size: 80),
                          const SizedBox(height: 16),
                          // Título
                          Text(
                            'Polired',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.04 * 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Únete al círculo académico exclusivo.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // ── Formulario ───────────────────────────────────
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Nombre
                                AppTextField(
                                  hint: 'Nombre',
                                  controller: _nombreCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El nombre es requerido';
                                    }
                                    if (v.trim().length < 2) {
                                      return 'Mínimo 2 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Apellido
                                AppTextField(
                                  hint: 'Apellido',
                                  controller: _apellidoCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El apellido es requerido';
                                    }
                                    if (v.trim().length < 2) {
                                      return 'Mínimo 2 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Email
                                AppTextField(
                                  hint: 'Correo universitario',
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'El correo es requerido';
                                    }
                                    // Validación básica de formato
                                    if (!RegExp(
                                            r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$')
                                        .hasMatch(v.trim())) {
                                      return 'Correo electrónico inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Contraseña
                                AppTextField(
                                  hint: 'Contraseña',
                                  isPassword: true,
                                  controller: _passCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'La contraseña es requerida';
                                    }
                                    if (v.length < 6) {
                                      return 'Mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Confirmar contraseña
                                AppTextField(
                                  hint: 'Confirmar contraseña',
                                  isPassword: true,
                                  controller: _confirmPassCtrl,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirma tu contraseña';
                                    }
                                    if (v != _passCtrl.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // ── Texto legal ──────────────────────────
                                Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.outline,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text:
                                              'Al registrarte, aceptas nuestras '),
                                      TextSpan(
                                        text: 'Condiciones',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const TextSpan(text: ', la '),
                                      TextSpan(
                                        text: 'Política de privacidad',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'Política de cookies',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 16),

                                // ── Botón registrarse ─────────────────────
                                PrimaryButton(
                                  label: 'Registrarse',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tarjeta secundaria: "¿Ya tienes cuenta?" ────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta? ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Inicia sesión',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Footer copyright ────────────────────────────────────
                    Text(
                      '@2024 POLIRED PARA LA POLITECNICA',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.outline,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
