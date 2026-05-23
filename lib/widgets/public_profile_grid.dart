import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import 'safe_network_image.dart';

/// A **Sliver** widget that renders a grid of posts.
/// Must be placed directly inside a [CustomScrollView]'s [slivers] list.
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
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 0.7,
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
              Transform.scale(
                scale: 1.15,
                child: SafeNetworkImage(
                  url: post.mediaUrls.first,
                  fit: BoxFit.cover,
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
