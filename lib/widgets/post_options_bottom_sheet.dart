import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import 'report_post_bottom_sheet.dart';

class PostOptionsBottomSheet extends StatelessWidget {
  final PostModel post;

  const PostOptionsBottomSheet({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Selector to listen to global save state
    final isSaved = context.select<PostStoreProvider, bool>(
      (store) => store.getPost(post.id)?.saved ?? post.saved,
    );

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
          InkWell(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ReportPostBottomSheet(postId: post.id),
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
          InkWell(
            onTap: () {
              context.read<PostStoreProvider>().toggleSave(post.id);
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
        ],
      ),
    );
  }
}
