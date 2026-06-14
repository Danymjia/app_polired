import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/polired_logo.dart';
import '../../widgets/primary_button.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/validators.dart';

/// Responsabilidad principal:
/// Interfaz para solicitar el enlace de recuperación de contraseña.
///
/// Flujo dentro de la app:
/// Accesible desde `LoginScreen`. Almacena dos estados visuales (formulario y confirmación).
///
/// Dependencias críticas:
/// - `AuthProvider`
///
/// Side Effects:
/// - Dispara el envío de correo desde `AuthProvider.forgotPassword`.
/// - Animación de estado al enviar.
///
/// Recordatorios técnicos y CQRS:
/// - Reinterpretación del HTML de referencia. Mantiene estado interno para la animación (`SingleTickerProviderStateMixin`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Animar transición al estado de éxito
      await _animCtrl.reverse();
      setState(() => _emailSent = true);
      _animCtrl.forward();
    } else {
      final msg = result.message ?? 'Error al enviar correo';
      final lowerMsg = msg.toLowerCase();
      
      if (lowerMsg.contains('no existe') || lowerMsg.contains('inexistente') || lowerMsg.contains('registrado')) {
        AppSnackbar.show(
          context,
          message: 'No existe una cuenta con este correo.',
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      // ── AppBar (del HTML: arrow_back + "Polired") ─────────────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => context.pop(),
          tooltip: 'Volver',
        ),
        title: Text(
          'Polired',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        titleSpacing: 0, // Pegado al leading (como en el HTML: mr-auto ml-2)
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _emailSent ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Estado 1: Formulario ──────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),

        // Logo con esquinas redondeadas (como en el HTML: rounded-2xl)
        PoliredLogo(size: 96, useRoundedRect: true),
        const SizedBox(height: 32),

        // Título
        Text(
          'Recupera tu acceso',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
            letterSpacing: -0.04 * 28,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Ingresa tu correo institucional y te enviaremos un enlace para que vuelvas a entrar a tu cuenta.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppTheme.onSurfaceVariant,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Formulario con label superior
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Correo universitario',
                hint: 'tu.nombre@epn.edu.ec',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Enviar enlace',
                isLoading: _isLoading,
                trailingIcon: Icons.arrow_forward,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Link volver al login
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 16, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '¿Volver al inicio de sesión?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── Estado 2: Correo enviado ──────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppTheme.success, size: 44),
        ),
        const SizedBox(height: 24),

        Text(
          '¡Correo enviado!',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Nota spam
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Si no ves el correo, revisa tu carpeta de spam.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        PrimaryButton(
          label: 'Volver al inicio de sesión',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
