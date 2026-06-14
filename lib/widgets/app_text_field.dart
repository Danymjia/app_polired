import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Responsabilidad principal:
/// Campo de texto estandarizado con el diseño base de Polired (bordes redondeados, fondo grisáceo).
///
/// Flujo dentro de la app:
/// Usado transversalmente en formularios de Auth, creación de redes, y edición de perfil.
///
/// Dependencias críticas:
/// - `AppTheme` (Tokens visuales).
///
/// Side Effects:
/// - Mantiene el estado interno de visibilidad (`_obscure`) cuando es tipo password.
///
/// Recordatorios técnicos y CQRS:
/// - No contiene validaciones de negocio, solo aplica la UI. Las reglas de validación se inyectan vía callback (`validator`).
class AppTextField extends StatefulWidget {
  final String hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;
  final String? label; // Etiqueta superior (para forgot password)

  const AppTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.label,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppTheme.onSurfaceVariant, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
