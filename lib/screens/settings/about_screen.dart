import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'INFORMACIÓN',
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ACERCA DE POLIRED',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Polired versión 1.0.0 (Build 42)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Polired es la red comunitaria universitaria definitiva, diseñada exclusivamente para estudiantes, profesores y personal administrativo. Nuestro objetivo principal es fomentar la conexión y la colaboración en todo el campus.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),
            const Text(
              'A través de Polired, puedes compartir recursos, participar en foros de discusión, unirte a grupos de estudio y mantenerte informado sobre los últimos eventos y noticias de la universidad. Creemos que la comunicación abierta es la clave para un entorno académico próspero.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),
            const Text(
              'Construida con tecnología moderna y un enfoque centrado en la privacidad, Polired garantiza un espacio seguro donde el crecimiento académico y personal van de la mano. ¡Únete a la conversación y haz que tu voz se escuche!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
