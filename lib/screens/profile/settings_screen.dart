import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../settings/notifications_screen.dart';
import '../settings/help_screen.dart';
import '../settings/support_screen.dart';
import '../settings/about_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/request_network_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppTheme.onBackground,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.outline, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Buscar',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Group 1: Tu interacción
            _buildSectionTitle('Tu interacción'),
            _buildMenuItem(context, 'Guardados', Icons.bookmark),
            _buildMenuItem(context, 'Me gusta', Icons.favorite),
            
            const SizedBox(height: 24),
            
            // Group 2: Ajustes del sistema
            _buildSectionTitle('Ajustes del sistema'),
            _buildMenuItem(context, 'Notificaciones', Icons.notifications, screen: const NotificationsScreen()),

            const SizedBox(height: 24),

            // Group 3: Soporte y recursos
            _buildSectionTitle('Soporte y recursos'),
            _buildMenuItem(context, 'Ayuda', Icons.help, screen: const HelpScreen()),
            _buildMenuItem(context, 'Asistencia', Icons.contact_support, screen: const SupportScreen()),
            _buildMenuItem(context, 'Información', Icons.info, screen: const AboutScreen()),
            _buildMenuItem(context, 'Políticas de privacidad', Icons.policy, screen: const PrivacyScreen()),

            const SizedBox(height: 24),

            // Featured Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestNetworkScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD1119), // primary-fixed (Rojo oscuro)
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hub, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Solicitar apertura de red',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 24, right: 24),
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

            const SizedBox(height: 40),
            
            // Divider
            const Divider(color: AppTheme.surfaceContainerHigh, height: 1, indent: 16, endIndent: 16),
            
            const SizedBox(height: 32),

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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Version
            const Center(
              child: Text(
                'POLIRED V2.4.0-ACADEMIC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AppTheme.outline,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen ?? DummyScreen(title: title)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.onBackground),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 24, color: AppTheme.outlineVariant),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: AppTheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
