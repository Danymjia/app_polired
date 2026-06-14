import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Responsabilidad principal:
/// Botón principal estandarizado de la aplicación con soporte para estado de carga y diseño base (Azul marino).
///
/// Flujo dentro de la app:
/// Usado en todas las llamadas a la acción (CTAs) principales: Login, Registrar, Enviar, Guardar.
///
/// Dependencias críticas:
/// - `AppTheme` (Tokens visuales).
///
/// Side Effects:
/// - Deshabilita interacciones automáticamente cuando `isLoading` es true.
///
/// Recordatorios técnicos y CQRS:
/// - Puramente UI (Dumb component). No debe contener lógica asíncrona ni manejar su propio estado.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.outlineVariant,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 18, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}
