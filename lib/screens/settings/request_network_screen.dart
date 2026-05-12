import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RequestNetworkScreen extends StatelessWidget {
  const RequestNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
          'Solicitud de Red',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppTheme.onBackground,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Fondo asimétrico (EPN)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.05,
              child: Text(
                'EPN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: AppTheme.primaryText,
                ),
              ),
            ),
          ),
          
          // Contenido principal
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva Red Universitaria',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Completa el siguiente formulario para proponer la creación de un nuevo espacio de interacción académica. Las solicitudes son revisadas por el comité editorial en un plazo de 48 horas.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Sección 1: Identidad
                _buildLabel('Nombre de la Red'),
                _buildTextField('Ej. Facultad de Arquitectura'),
                const SizedBox(height: 16),
                
                _buildLabel('Siglas'),
                _buildTextField('Ej. FA-UP'),
                const SizedBox(height: 16),
                
                _buildLabel('Descripción/Propósito'),
                _buildTextField('Describe brevemente el objetivo académico de esta red...', maxLines: 4),
                const SizedBox(height: 24),

                // Sección 2: Contacto
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nombre del Solicitante'),
                      _buildTextField('Tu nombre completo', isWhite: true),
                      const SizedBox(height: 16),
                      _buildLabel('Correo Institucional'),
                      _buildTextField('usuario@universidad.edu', isWhite: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sección 3: Media
                _buildLabel('Adjuntar Logo (opcional)'),
                InkWell(
                  onTap: () {
                    // Funcionalidad futura
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceContainerHighest, width: 2, style: BorderStyle.solid), // Flutter no soporta BorderStyle.dashed nativo fácil sin librerías, usamos solid
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: AppTheme.outlineVariant, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Click para subir imagen',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Enviar
                ElevatedButton(
                  onPressed: () {
                    // Funcionalidad futura
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00204A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text('Enviar solicitud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                
                const Center(
                  child: Text(
                    'SUJETO A TÉRMINOS Y CONDICIONES INSTITUCIONALES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.outline,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1, bool isWhite = false}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.outlineVariant, fontSize: 14),
        filled: true,
        fillColor: isWhite ? Colors.white : AppTheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBD1119), width: 1.5), // primary-fixed
        ),
      ),
    );
  }
}
