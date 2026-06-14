import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import '../services/command_bus.dart';
import '../models/commands/feed_command.dart';
import '../providers/auth_provider.dart';
import 'report_post_bottom_sheet.dart';

/// Responsabilidad principal:
/// Presenta opciones contextuales sobre una Publicación (Reportar, Guardar/Eliminar de Guardados, Eliminar Publicación).
///
/// Flujo dentro de la app:
/// Invocado al tocar el icono de opciones (3 puntos) en la cabecera de un `PostCard`.
///
/// Dependencias críticas:
/// - `CommandBus` (Para enviar `ToggleSaveCommand`, `DeletePostCommand`).
/// - `PostStoreProvider` (Para verificar si está guardado localmente).
/// - `ReportPostBottomSheet`.
///
/// Side Effects:
/// - Despacha comandos CQRS que alteran el estado global del Post.
/// - Cierra la hoja actual antes de abrir modales secundarios para evitar apilamiento de BottomSheets.
///
/// Recordatorios técnicos y CQRS:
/// - La opción "Eliminar publicación" solo es visible si el usuario autenticado es el autor (`isAuthor`).
class PostOptionsBottomSheet extends StatelessWidget {
  final PostModel post;

  const PostOptionsBottomSheet({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Selector to listen to global save state
    final isSaved = context.select<PostStoreProvider, bool>(
      (store) => store.getPost(post.id)?.saved ?? post.saved,
    );

    final currentUserId = context.read<AuthProvider>().user?.id;
    final isAuthor = currentUserId != null && currentUserId == post.authorId;

    return Container(
      padding: EdgeInsets.fromLTRB(0, 12, 0, MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 32),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16), // mb-4

          // Reportar
          if (!isAuthor)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReportPostBottomSheet(postId: post.id, isArticle: post.isArticle),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16), // py-4
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.surfaceContainerHigh, // border-neutral-100
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Reportar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w600, // font-semibold
                    color: AppTheme.error, // text-error
                  ),
                ),
              ),
            ),

          // Guardar / Quitar de Guardados
          if (!isAuthor)
            InkWell(
              onTap: () {
                context.read<CommandBus>().dispatch(ToggleSaveCommand(postId: post.id));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSaved
                          ? 'Publicación eliminada de guardados'
                          : 'Publicación guardada con éxito',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16), // py-4
                child: Text(
                  isSaved ? 'Eliminar de guardados' : 'Guardar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w500, // font-medium
                    color: AppTheme.onSurface, // text-on-surface
                  ),
                ),
              ),
            ),

          // Eliminar Publicación (solo autor)
          if (isAuthor)
            InkWell(
              onTap: () {
                _confirmDelete(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.surfaceContainerHigh,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Eliminar publicación',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar publicación?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final commandBus = context.read<CommandBus>();
              final messenger = ScaffoldMessenger.of(context);
              final authProvider = context.read<AuthProvider>();
              
              Navigator.pop(ctx); // Cierra el dialog
              Navigator.pop(context); // Cierra el bottom sheet

              commandBus.dispatch(DeletePostCommand(postId: post.id)).then((result) {
                if (result.success) {
                  authProvider.decrementPublicacionesCount();
                }
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: result.success ? AppTheme.primary : AppTheme.error,
                    content: Text(result.success ? 'Publicación eliminada' : (result.error ?? 'Error al eliminar')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
