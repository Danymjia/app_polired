import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import 'safe_network_image.dart';

class PublicProfileGrid extends StatelessWidget {
  final List<String> postIds;
  final ScrollController scrollController;
  final bool isFetchingMore;

  const PublicProfileGrid({
    super.key,
    required this.postIds,
    required this.scrollController,
    required this.isFetchingMore,
  });

  @override
  Widget build(BuildContext context) {
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

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= postIds.length) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                ),
              );
            }
            final postId = postIds[index];
            return _GridCell(postId: postId);
          },
          childCount: postIds.length + (isFetchingMore ? 3 : 0),
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final String postId;

  const _GridCell({required this.postId});

  @override
  Widget build(BuildContext context) {
    // Select only this specific post to avoid re-rendering the whole grid
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
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Stack(
          fit: StackFit.expand,
        children: [
          if (post.hasImage && post.mediaUrls.isNotEmpty)
            SafeNetworkImage(
              url: post.mediaUrls.first,
              fit: BoxFit.cover,
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
