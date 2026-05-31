import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/core/base_screen.dart';
import '../../widgets/core/keyboard_aware_layout.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/polired_logo.dart';
import '../../widgets/primary_button.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/validators.dart';
import 'package:flutter/gestures.dart';
import '../settings/legal_document_screen.dart';

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
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      // Nota: Si el backend requiere teléfono, habría que pasarlo al método register().
      // Por ahora se asume que auth_service soporta solo nombre, apellido, email y password,
      // pero la validación ya queda implementada aquí visualmente.
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      AppSnackbar.show(
        context,
        message: result.message ?? 'Te enviamos un correo para activar tu cuenta',
        type: SnackbarType.success,
      );
      // Opcional: Redirigir al usuario al login
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/login');
      });
    } else {
      final msg = result.message ?? 'Error al registrar';
      final lowerMsg = msg.toLowerCase();
      
      if (lowerMsg.contains('registrado') || lowerMsg.contains('ya existe')) {
        AppSnackbar.show(
          context,
          message: 'El usuario o correo ya está registrado',
          type: SnackbarType.error,
        );
      } else {
        AppSnackbar.show(
          context,
          message: msg,
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      safeAreaTop: true,
      safeAreaBottom: true,
      resizeToAvoidBottomInset: true,
      dismissKeyboardOnTap: true,
      backgroundColor: const Color(0xFFF9F9F9),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: KeyboardAwareLayout(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // ── Contenido central ────────────────────────────────────
              ConstrainedBox(
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
                          const SizedBox(height: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Únete al círculo académico exclusivo.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),

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
                                  validator: (v) => Validators.name(v, 'El nombre'),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                // Apellido
                                AppTextField(
                                  hint: 'Apellido',
                                  controller: _apellidoCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => Validators.name(v, 'El apellido'),
                                ),

                                const SizedBox(height: AppSpacing.sm),
                                // Email
                                AppTextField(
                                  hint: 'Correo universitario',
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                // Contraseña
                                AppTextField(
                                  hint: 'Contraseña',
                                  isPassword: true,
                                  controller: _passCtrl,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.strongPassword,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                // Confirmar contraseña
                                AppTextField(
                                  hint: 'Confirmar contraseña',
                                  isPassword: true,
                                  controller: _confirmPassCtrl,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
                                ),

                                const SizedBox(height: AppSpacing.sm),

                                // ── Texto legal ──────────────────────────
                                Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.outline,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Al registrarte, aceptas nuestros '),
                                      TextSpan(
                                        text: 'Términos y Condiciones',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText.withValues(alpha: 0.8),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const LegalDocumentScreen(
                                                  title: 'Términos y Condiciones',
                                                  assetPath: 'assets/docs/terminos_condiciones.md',
                                                ),
                                              ),
                                            );
                                          },
                                      ),
                                      const TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'Política de Privacidad',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText.withValues(alpha: 0.8),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const LegalDocumentScreen(
                                                  title: 'Política de Privacidad',
                                                  assetPath: 'assets/docs/politica_privacidad.md',
                                                ),
                                              ),
                                            );
                                          },
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: AppSpacing.md),

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

                    const SizedBox(height: AppSpacing.sm),

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
                  ],
                ),
              ),

              const Expanded(child: SizedBox()), // empuja footer al fondo

              const SizedBox(height: AppSpacing.xl),

              // ── Footer copyright ────────────────────────────────────
              Text(
                '@2026 POLIRED PARA LA POLITECNICA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.outline,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
