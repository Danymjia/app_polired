import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/polired_logo.dart';

/// Responsabilidad principal:
/// Pantalla de carga inicial transitoria que enruta al usuario al App o al Login.
///
/// Flujo dentro de la app:
/// Se muestra inmediatamente al arrancar. Corre animaciones visuales y a los 2 segundos evalúa el flag `isAuthenticated` del `AuthProvider`.
///
/// Dependencias críticas:
/// - `AuthProvider` (Determina la ruta destino).
/// - `go_router` (Reemplazo absoluto del stack de navegación).
///
/// Side Effects:
/// - Ninguno propio.
///
/// Recordatorios técnicos y CQRS:
/// - Race Condition Potencial: El enrutamiento depende de un `Future.delayed` de 2000ms. Si la lectura del Disco (StorageService) en `AuthProvider` toma más de 2 segundos, mandará al usuario a Login incorrectamente. Se debe escuchar reactivamente al estado "inicializado" en lugar de adivinar el tiempo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Contenido principal centrado ─────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo circular
                      const PoliredLogo(size: 128),
                      const SizedBox(height: 20),
                      // Nombre de la app
                      Text(
                        'Polired',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: -0.04 * 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'ECOSISTEMA UNIVERSITARIO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.outline,
                      letterSpacing: 0.05 * 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
