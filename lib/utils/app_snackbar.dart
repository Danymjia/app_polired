import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackbarType { success, error, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
  }) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFFE8F5E9); // Verde muy sutil
        iconColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case SnackbarType.error:
        backgroundColor = const Color(0xFFFFEBEE); // Rojo elegante sutil
        iconColor = const Color(0xFFC62828);
        icon = Icons.error_rounded;
        break;
      case SnackbarType.info:
        backgroundColor = const Color(0xFFE3F2FD); // Azul sutil
        iconColor = const Color(0xFF1565C0);
        icon = Icons.info_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: iconColor, // Texto del mismo color pero más oscuro/visible
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
