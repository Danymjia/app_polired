import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_store_provider.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/post_image_carousel.dart';
import '../../../widgets/comment_tree_sheet.dart';

/// Card unificada para el Explore Feed.
///
/// Misma estructura, misma jerarquía visual y mismo sistema de interacciones
/// para Noticias, Marketplace y Cursos.
///
/// Lee el estado únicamente desde [PostStoreProvider] — sin estado local.
class ExplorePostCard extends StatelessWidget {
  final PostModel post;

  const ExplorePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _CardHeader(post: post),

          // ── Título (si existe y hay imagen, se muestra antes de la imagen) ─
          if (post.titulo.isNotEmpty && !post.hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                post.titulo,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Media / Contenido visual principal ────────────────────────────
          if (post.hasImage)
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PostImageCarousel(mediaUrls: post.mediaUrls),
                  // Título overlay encima de la imagen (si existe)
                  if (post.titulo.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(180),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          post.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  // Price Badge (Marketplace)
                  if (post.isArticle && post.precio != null && post.priceLabel.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(240),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          post.priceLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (post.displayContent.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: AppTheme.surfaceContainerLow,
              child: Text(
                post.displayContent,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                  height: 1.5,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Acciones sociales ─────────────────────────────────────────────
          _CardActions(post: post),

          // ── Caption (autor + contenido breve) ─────────────────────────────
          _CardCaption(post: post),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final PostModel post;

  const _CardHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar
          _AuthorAvatar(imageUrl: post.authorImageUrl, radius: 18),
          const SizedBox(width: 9),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorUsername.isNotEmpty ? post.authorUsername : 'Usuario',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.authorId.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF1D3557),
                        size: 13,
                      ),
                    ],
                  ],
                ),
                if (post.networkName.isNotEmpty)
                  Text(
                    post.networkName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Tiempo + More
          Text(
            post.timeAgo,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.more_horiz,
            color: AppTheme.onSurface.withAlpha(130),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─── Acciones sociales ─────────────────────────────────────────────────────────
class _CardActions extends StatelessWidget {
  final PostModel post;

  const _CardActions({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Like
          _SocialAction(
            icon: post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            count: post.likesCount,
            color: post.likedByMe ? const Color(0xFFE91E63) : null,
            onTap: () => context.read<PostStoreProvider>().toggleLike(post.id),
          ),
          const SizedBox(width: 18),
          // Comment
          _SocialAction(
            icon: Icons.mode_comment_outlined,
            count: post.commentsCount,
            onTap: () => _openComments(context),
          ),
          const SizedBox(width: 18),
          // Share
          _SocialAction(
            icon: Icons.ios_share_outlined,
            onTap: () {},
          ),
          const Spacer(),
          // Save
          GestureDetector(
            onTap: () => context.read<PostStoreProvider>().toggleSave(post.id),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  post.savedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  key: ValueKey(post.savedByMe),
                  size: 24,
                  color: post.savedByMe
                      ? AppTheme.primary
                      : AppTheme.onSurface.withAlpha(180),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentTreeSheet(postId: post.id),
    );
  }
}

// ─── Caption ──────────────────────────────────────────────────────────────────
class _CardCaption extends StatelessWidget {
  final PostModel post;

  const _CardCaption({required this.post});

  @override
  Widget build(BuildContext context) {
    final content = post.displayContent;
    if (content.isEmpty && post.commentsCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 16, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.isNotEmpty)
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurface,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '${post.authorUsername.isNotEmpty ? post.authorUsername : 'Usuario'} ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  TextSpan(
                    text: content.length > 120 ? '${content.substring(0, 120)}...' : content,
                  ),
                ],
              ),
            ),
          if (post.commentsCount > 0) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentTreeSheet(postId: post.id),
                );
              },
              child: Text(
                'Ver los ${post.commentsCount} comentarios',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Social Action (icono + contador) ─────────────────────────────────────────
class _SocialAction extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color? color;
  final VoidCallback onTap;

  const _SocialAction({
    required this.icon,
    required this.onTap,
    this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 24,
                color: color ?? AppTheme.onSurface.withAlpha(180),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Author Avatar ─────────────────────────────────────────────────────────────
class _AuthorAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const _AuthorAvatar({this.imageUrl, this.radius = 18});

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
                Icons.person_rounded,
                color: AppTheme.onSurface.withAlpha(130),
                size: radius,
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: AppTheme.onSurface.withAlpha(130),
              size: radius,
            ),
    );
  }
}
