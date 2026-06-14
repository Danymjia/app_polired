import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/theme.dart';

/// Responsabilidad principal:
/// Visualizador genérico de documentos legales (Políticas de Privacidad, Términos y Condiciones) en formato Markdown.
///
/// Flujo dentro de la app:
/// Se instancia desde `SettingsScreen` pasándole la ruta del asset local.
///
/// Dependencias críticas:
/// - `flutter_markdown` (para parsear y renderizar el `.md` a widgets nativos).
/// - `rootBundle` (para leer el archivo desde los assets de la app).
///
/// Side Effects:
/// - Lee un archivo físico del bundle en tiempo de ejecución.
///
/// Recordatorios técnicos y CQRS:
/// - Requiere que los archivos `.md` estén correctamente declarados en el `pubspec.yaml`.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

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
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el documento', style: TextStyle(color: AppTheme.error)));
          }

          final data = snapshot.data ?? '';

          return Markdown(
            data: data,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
              h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, height: 2.0),
              p: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.6),
              listBullet: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }
}
