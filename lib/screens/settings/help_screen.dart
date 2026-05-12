import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../profile/settings_screen.dart'; // Para reutilizar el DummyScreen temporalmente

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      '¿Cómo puedo unirme a una nueva red?',
      '¿Cómo cambio mi foto de perfil?',
      '¿Cómo puedo denunciar una publicación?',
      '¿Cómo recupero mi contraseña?',
      '¿Cómo puedo crear mi propia red comunitaria?',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayuda',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.surfaceContainerHighest,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Preguntas Frecuentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...faqs.map((faq) => _buildFaqItem(context, faq)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question) {
    return InkWell(
      onTap: () {
        // Redirige a pantalla placeholder
        Navigator.push(context, MaterialPageRoute(builder: (_) => DummyScreen(title: question)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
