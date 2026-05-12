import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // background from HTML
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacidad',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Última actualización: Octubre 2023. Tu privacidad es importante para nosotros. Esta política explica cómo recopilamos, usamos y compartimos tu información en Polired.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              title: '1. Recopilación de datos',
              content: 'Recopilamos la información que nos proporcionas directamente al crear una cuenta, como tu nombre, dirección de correo electrónico institucional, programa académico y cualquier otra información del perfil que decidas compartir. También recopilamos datos sobre tu actividad dentro de la aplicación, como las redes a las que te unes y los posts con los que interactúas.',
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              title: '2. Uso de la información',
              content: 'Utilizamos tu información para proporcionar, mantener y mejorar nuestros servicios. Esto incluye personalizar el contenido de tu feed académico, recomendarte grupos de estudio relevantes y enviarte notificaciones sobre actividades universitarias importantes. No utilizamos tus datos para publicidad dirigida fuera del ecosistema universitario.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '3. Compartir con terceros',
              content: 'No vendemos tu información personal. Solo compartimos datos con terceros cuando es estrictamente necesario para proporcionar nuestros servicios (como proveedores de alojamiento en la nube), cuando lo exige la ley institucional, o con tu consentimiento explícito. Los datos compartidos con proveedores de servicios están sujetos a estrictos acuerdos de confidencialidad.',
            ),
            const SizedBox(height: 48),

            // Contact Support Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mail, size: 32, color: AppTheme.secondary),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Tienes dudas sobre tu privacidad?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Contacta con el equipo de soporte de Polired.',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Acción futura
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF243C5E), // on-secondary-fixed-variant
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Text('Contactar Soporte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
