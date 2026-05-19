import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/network_service.dart';

class RequestNetworkScreen extends StatefulWidget {
  const RequestNetworkScreen({super.key});

  @override
  State<RequestNetworkScreen> createState() => _RequestNetworkScreenState();
}

class _RequestNetworkScreenState extends State<RequestNetworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────────────────────────

  String? _validateNombre(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'El nombre es requerido';
    if (val.length < 3) return 'Mínimo 3 caracteres';
    if (val.length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  String? _validateDescripcion(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'La descripción es requerida';
    if (val.length < 10) return 'Mínimo 10 caracteres';
    if (val.length > 300) return 'Máximo 300 caracteres';
    return null;
  }

  // ── Submission ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final networkService = context.read<NetworkService>();

    try {
      final result = await networkService.solicitarCreacionRed(
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Solicitud enviada! Será revisada en 48 horas.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        final msg = result.message ?? 'Error al enviar la solicitud';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión. Inténtalo de nuevo.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          'Solicitud de red',
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
      body: Stack(
        children: [
          // Subtle background watermark
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.04,
              child: Text(
                'EPN',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  height: 1.0,
                ),
              ),
            ),
          ),

          // Main content
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Red Universitaria',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onBackground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa el formulario para proponer la creación de un nuevo espacio de interacción académica. Las solicitudes son revisadas en un plazo de 48 horas.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Campo: Nombre de la red ─────────────────────────────
                  _buildLabel('Nombre de la red *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nombreCtrl,
                    enabled: !_isSubmitting,
                    textInputAction: TextInputAction.next,
                    validator: _validateNombre,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
                    decoration: _inputDecoration('Ej. Facultad de Ingeniería Civil'),
                  ),
                  const SizedBox(height: 20),

                  // ── Campo: Descripción ──────────────────────────────────
                  _buildLabel('Descripción / Propósito *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descripcionCtrl,
                    enabled: !_isSubmitting,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    validator: _validateDescripcion,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
                    decoration: _inputDecoration('Describe brevemente el objetivo académico de esta red...'),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _descripcionCtrl,
                      builder: (context, value, child) => Text(
                        '${value.text.trim().length}/300',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: value.text.trim().length > 280
                              ? AppTheme.error
                              : AppTheme.outline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Submit button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primary.withAlpha(80),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Enviar solicitud',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      'SUJETO A TÉRMINOS Y CONDICIONES INSTITUCIONALES',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.outlineVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppTheme.outlineVariant, fontSize: 13),
      filled: true,
      fillColor: AppTheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: AppTheme.error),
    );
  }
}
