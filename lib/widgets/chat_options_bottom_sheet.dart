import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'report_user_bottom_sheet.dart';

/// Responsabilidad principal:
/// Presenta las opciones disponibles para interactuar con un usuario desde un chat (ej. Ver Perfil, Reportar).
///
/// Flujo dentro de la app:
/// Invocado desde la pantalla de Chat (`ChatScreen`) al pulsar el botón de opciones.
///
/// Dependencias críticas:
/// - `go_router` para navegación.
/// - `ReportUserBottomSheet`.
///
/// Side Effects:
/// - Muestra overlays de navegación (Navega a un nuevo sheet o pantalla cerrando el actual primero).
///
/// Recordatorios técnicos y CQRS:
/// - Siempre usar `Navigator.pop(context)` antes de navegar a otra pantalla para evitar bugs de enrutamiento con los BottomSheets.
class ChatOptionsBottomSheet extends StatelessWidget {
  final String contactId;
  final String contactName;

  const ChatOptionsBottomSheet({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.onSurface),
            title: Text(
              'Ver perfil',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
            onTap: () {
              // Cerrar el sheet primero para evitar bugs en la navegación hacia atrás
              Navigator.pop(context);
              context.push('/explore/public-profile/$contactId');
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: AppTheme.error),
            title: Text(
              'Reportar usuario',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra este sheet de opciones
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ReportUserBottomSheet(
                  userId: contactId,
                  userName: contactName,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
