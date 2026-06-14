import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/post_service.dart';

/// Responsabilidad principal:
/// Formulario para que el usuario envíe tickets de soporte técnico, reportes de bugs o problemas con su cuenta.
///
/// Flujo dentro de la app:
/// Accesible desde `SettingsScreen` -> "Asistencia" o desde el final de un FAQ en `HelpDetailScreen`.
///
/// Dependencias críticas:
/// - `PostService` (reutilizado para el envío genérico de reportes de la app `reportApp`).
///
/// Side Effects:
/// - Envía la descripción y categoría del problema al backend.
///
/// Recordatorios técnicos y CQRS:
/// - Mantiene el estado del formulario localmente y bloquea envíos duplicados con `_isSubmitting`.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _problemType = 'Otro';
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _descController.text.trim().isNotEmpty;
  }

  Future<void> _submitReport() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final postService = context.read<PostService>();
      final result = await postService.reportApp(
        tipo: _problemType,
        descripcion: _descController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reporte enviado correctamente',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'Error al enviar el reporte',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de conexión al enviar el reporte',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

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
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Asistencia',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo podemos ayudarte?',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa el formulario a continuación detallando el inconveniente técnico o problema con contenidos para reportarlo a nuestro equipo.',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Report title / Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_problem_outlined, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportar un problema',
                          style: GoogleFonts.inter(
                            fontSize: 15.5, 
                            fontWeight: FontWeight.w700, 
                            color: AppTheme.onSurface
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fallas técnicas, de cuenta o contenidos inapropiados',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Radios Section
            Text(
              'TIPO DE PROBLEMA',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Column(
                children: [
                  _buildRadioItem('Error Técnico', 'Error Técnico', showDivider: true),
                  _buildRadioItem('Problema con la cuenta', 'Problema con la cuenta', showDivider: true),
                  _buildRadioItem('Contenidos Inapropiados', 'Contenidos Inapropiados', showDivider: true),
                  _buildRadioItem('Otro', 'Otro', showDivider: false),
                ],
              ),
            ),
            
            const SizedBox(height: 28),

            // Description
            Text(
              'DESCRIPCIÓN DEL PROBLEMA',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe detalladamente el problema...',
                hintStyle: GoogleFonts.inter(color: AppTheme.outline, fontSize: 13),
                fillColor: AppTheme.surfaceContainerLow,
                filled: true,
                counterStyle: GoogleFonts.inter(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            ElevatedButton(
              onPressed: _isValid && !_isSubmitting ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withAlpha(80),
                disabledForegroundColor: Colors.white.withAlpha(120),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Enviar',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(String title, String value, {required bool showDivider}) {
    final isSelected = _problemType == value;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _problemType = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: AppTheme.surfaceContainerHigh,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
