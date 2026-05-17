import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import 'safe_network_image.dart';
import 'post_image_carousel.dart';

/// Tarjeta de publicación adaptada al modelo real del backend.
/// Soporta publicaciones de texto, imagen y video (con poster).
/// Muestra: avatar del autor, username/nombre, fecha relativa,
/// contenido, imagen (si aplica), likes y comentarios.
class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      color: AppTheme.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _AuthorAvatar(
                  imageUrl: post.authorImageUrl,
                  name: post.authorUsername,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
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
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.more_horiz,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),

          // ── Imagen (si aplica) ───────────────────────────────────────────────
          if (post.hasImage) PostImageCarousel(mediaUrls: post.mediaUrls),

          // ── Acciones ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  color: AppTheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentsCount}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.bookmark_border,
                  color: AppTheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────────────
          if (post.contenido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _PostContent(post: post),
            ),

          // Separador
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppTheme.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }
}

// ─── Avatar del autor ─────────────────────────────────────────────────────────
class _AuthorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _AuthorAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircularNetworkAvatar(
      imageUrl: imageUrl,
      initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
      size: 36,
      backgroundColor: AppTheme.surfaceContainerLow,
      initialsStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}



// ─── Contenido textual ────────────────────────────────────────────────────────
class _PostContent extends StatefulWidget {
  final PostModel post;
  const _PostContent({required this.post});

  @override
  State<_PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<_PostContent> {
  bool _expanded = false;
  static const int _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final text = widget.post.contenido;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
            children: [
              TextSpan(
                text: '${widget.post.authorUsername} ',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              TextSpan(text: text),
            ],
          ),
          maxLines: _expanded ? null : _maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (!_expanded && text.length > 200)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Text(
              'Ver más',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
