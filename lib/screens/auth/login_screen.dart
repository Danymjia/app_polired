import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/polired_logo.dart';
import '../../widgets/primary_button.dart';

/// Login Screen — reinterpretación del HTML de referencia en Flutter.
/// Layout: logo + título centrado, campos de email/password, botón, footer.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Error al iniciar sesión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      // Evita que el teclado empuje el layout
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              // ── Línea de acento superior (del HTML) ─────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF7D0009)],
                    ),
                  ),
                ),
              ),

              // ── Contenido scrolleable ────────────────────────────────────
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // ── Brand ──────────────────────────────────────────
                        const PoliredLogo(size: 80),
                        const SizedBox(height: 16),
                        Text(
                          'Polired',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryText,
                            letterSpacing: -0.04 * 36,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Formulario ─────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                hint: 'Teléfono, usuario o correo electrónico',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailCtrl,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingresa tu correo';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                hint: 'Contraseña',
                                isPassword: true,
                                controller: _passCtrl,
                                textInputAction: TextInputAction.done,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }
                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Botón principal ─────────────────────────
                              PrimaryButton(
                                label: 'Iniciar sesión',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _submit,
                              ),
                              const SizedBox(height: 12),

                              // ── Olvidé mi contraseña ────────────────────
                              GestureDetector(
                                onTap: () => context.push('/forgot-password'),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80), // espacio para footer fijo
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer fijo inferior ─────────────────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Divisor
                    Container(height: 1, color: AppTheme.surfaceContainerHigh),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta? ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '@2024 POLIRED PARA LA POLITECNICA',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.outline.withValues(alpha: 0.6),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
