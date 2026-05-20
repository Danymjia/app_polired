import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../settings/notifications_screen.dart';
import '../settings/help_screen.dart';
import '../settings/support_screen.dart';
import '../settings/about_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/request_network_screen.dart';
import 'saved_posts_screen.dart';
import 'liked_posts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (auth) => auth.user?.esAdminRed ?? false,
    );
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración y actividad',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Group 1: Tu interacción
            _buildSectionTitle('Tu interacción'),
            _buildMenuItem(
              context,
              'Guardados',
              Icons.bookmark_outline,
              screen: const SavedPostsScreen(),
            ),
            _buildMenuItem(
              context,
              'Me gusta',
              Icons.favorite_outline,
              screen: const LikedPostsScreen(),
            ),

            const SizedBox(height: 20),

            // Group 2: Ajustes del sistema
            _buildSectionTitle('Ajustes del sistema'),
            _buildMenuItem(
              context,
              'Notificaciones',
              Icons.notifications_outlined,
              screen: const NotificationsScreen(),
            ),

            const SizedBox(height: 20),

            // Group 3: Soporte y recursos
            _buildSectionTitle('Soporte y recursos'),
            _buildMenuItem(context, 'Ayuda', Icons.help_outline, screen: const HelpScreen()),
            _buildMenuItem(context, 'Asistencia', Icons.support_agent_outlined, screen: const SupportScreen()),
            _buildMenuItem(context, 'Información', Icons.info_outline, screen: const AboutScreen()),
            _buildMenuItem(context, 'Políticas de privacidad', Icons.policy_outlined, screen: const PrivacyScreen()),

            // Featured Action — solo para usuarios SIN rol admin_red
            if (!isAdmin) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestNetworkScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Solicitar apertura de red',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 24, right: 24),
                child: Text(
                  'Envía una solicitud para crear un nuevo nodo de red en tu facultad o departamento académico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.outline,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Divider
            const Divider(color: AppTheme.surfaceContainerHigh, height: 1, indent: 16, endIndent: 16),

            const SizedBox(height: 28),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_outlined, size: 20, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Cerrar sesión',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Version
            Center(
              child: Text(
                'POLIRED V2.4.0-ACADEMIC',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AppTheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.outline,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, {Widget? screen}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen ?? DummyScreen(title: title)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.onBackground),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

// Pantalla Placeholder para cada opción
class DummyScreen extends StatelessWidget {
  final String title;

  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.surfaceContainerLowest,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, size: 56, color: AppTheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta función estará disponible próximamente.',
              style: TextStyle(color: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
