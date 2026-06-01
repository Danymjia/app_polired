import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Responsabilidad principal:
/// Renderizar la cuadrícula de publicaciones/artículos en el Perfil, utilizando Slivers para integrarse fluidamente en un `CustomScrollView` principal.
///
/// Flujo dentro de la app:
/// Componente tonto (Dumb Component) a nivel de lista: recibe un listado crudo de `String` (postIds). Delega la resolución final de la entidad a sus hijos `_GridCell`, los cuales consultan al `PostStoreProvider`.
///
/// Dependencias críticas:
/// - `PostStoreProvider` (Entity Cache para hidratar los IDs).
/// - `CachedNetworkImage` (Para manejo veloz de imágenes redimensionadas/recortadas en caché local).
///
/// Side Effects:
/// - Loading Eterno: Si un ID pasado en `postIds` fue borrado del `PostStoreProvider` pero no de la lista del Feed, la celda hija girará un `CircularProgressIndicator` para siempre.
///
/// Recordatorios técnicos y CQRS:
/// - Alto Rendimiento: Separación excelente. Como la grilla solo mapea IDs y delega el `context.select` a los hijos directos (`_GridCell`), un "Like" o mutación en un Post solo reconstruye esa celda específica y no la grilla entera ni la pantalla de Perfil.
class PublicProfileGrid extends StatelessWidget {
  final List<String> postIds;
  final bool isFetchingMore;

  // Legacy param kept so existing call-sites don't break; ignored internally.
  final ScrollController? scrollController;

  const PublicProfileGrid({
    super.key,
    required this.postIds,
    required this.isFetchingMore,
    this.scrollController, // kept for back-compat, not used
  });

  @override
  Widget build(BuildContext context) {
    // Empty state — must be a Sliver
    if (postIds.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_off_rounded, size: 48, color: AppTheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Aún no hay publicaciones',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1.5,
            crossAxisSpacing: 1.5,
            childAspectRatio: 0.8, // ← más alto que ancho, como Instagram
          ),
          itemCount: postIds.length,
          itemBuilder: (context, index) => _GridCell(postId: postIds[index]),
        ),
        if (isFetchingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final String postId;

  const _GridCell({required this.postId});

  @override
  Widget build(BuildContext context) {
    final post = context.select<PostStoreProvider, PostModel?>(
      (store) => store.getPost(postId),
    );

    if (post == null) {
      return Container(
        color: AppTheme.surfaceContainerLow,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.hasImage && post.mediaUrls.isNotEmpty)
              ClipRect(
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  memCacheWidth: 300,
                  placeholder: (context, url) => Container(
                    color: AppTheme.surfaceContainerLow,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceContainerLow,
                    child: const Icon(Icons.broken_image_outlined, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.05),
                      AppTheme.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    post.titulo.isNotEmpty ? post.titulo : post.displayContent,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (post.isArticle)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            if (post.mediaUrls.length > 1 && !post.isArticle)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
