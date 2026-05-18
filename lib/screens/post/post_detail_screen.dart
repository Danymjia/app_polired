import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/post_store_provider.dart';
import '../../widgets/post_image_carousel.dart';
import '../../widgets/comment_tree_sheet.dart';
import '../../widgets/safe_network_image.dart';

/// Pantalla de detalle de publicación.
/// Obtiene el PostModel desde el PostStoreProvider (estado global).
/// Soporta multimedia, likes, comentarios y saved completamente conectados al backend.
class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Publicación',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          final post = context.select<PostStoreProvider, PostModel?>(
            (store) => store.getPost(postId),
          );

          if (post == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          return _PostDetailBody(post: post);
        },
      ),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  final PostModel post;

  const _PostDetailBody({required this.post});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _Avatar(imageUrl: post.authorImageUrl, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorUsername.isNotEmpty ? post.authorUsername : 'Usuario',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (post.networkName.isNotEmpty)
                            Text(
                              post.networkName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      post.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Título ────────────────────────────────────────────────────
              if (post.titulo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    post.titulo,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),

              // ── Media ─────────────────────────────────────────────────────
              if (post.hasImage) ...[
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PostImageCarousel(mediaUrls: post.mediaUrls),
                ),
              ],

              // ── Precio (Artículos) ────────────────────────────────────────
              if (post.isArticle && post.priceLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withAlpha(60)),
                    ),
                    child: Text(
                      post.priceLabel,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),

              // ── Contenido ─────────────────────────────────────────────────
              if (post.displayContent.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    post.displayContent,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),

              const Divider(height: 1, thickness: 0.5, color: AppTheme.surfaceContainerHigh),

              // ── Acciones ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _PostActions(post: post),
              ),

              const Divider(height: 1, thickness: 0.5, color: AppTheme.surfaceContainerHigh),

              // ── Cabecera comentarios ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Comentarios',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),

              // ── Abrir sheet de comentarios ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentTreeSheet(postId: post.id),
                    );
                  },
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  label: Text('Ver ${post.commentsCount} comentarios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    foregroundColor: AppTheme.onSurface,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  final PostModel post;

  const _PostActions({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like
        _ActionButton(
          icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
          color: post.likedByMe ? AppTheme.primary : AppTheme.onSurface.withAlpha(180),
          label: '${post.likesCount}',
          onTap: () => context.read<PostStoreProvider>().toggleLike(post.id),
        ),
        const SizedBox(width: 20),
        // Comment
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: '${post.commentsCount}',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CommentTreeSheet(postId: post.id),
            );
          },
        ),
        const Spacer(),
        // Save
        _ActionButton(
          icon: post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
          color: post.savedByMe ? AppTheme.primary : AppTheme.onSurface.withAlpha(180),
          onTap: () => context.read<PostStoreProvider>().toggleSave(post.id),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: color ?? AppTheme.onSurface.withAlpha(180),
          ),
          if (label != null) ...[
            const SizedBox(width: 5),
            Text(
              label!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const _Avatar({this.imageUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? SafeNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorWidget: Icon(
                Icons.person,
                color: AppTheme.onSurface.withAlpha(153),
                size: radius,
              ),
            )
          : Icon(
              Icons.person,
              color: AppTheme.onSurface.withAlpha(153),
              size: radius,
            ),
    );
  }
}
