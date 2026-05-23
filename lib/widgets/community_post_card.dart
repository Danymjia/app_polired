import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import 'package:provider/provider.dart';
import '../../services/command_bus.dart';
import '../../models/commands/feed_command.dart';
import 'safe_network_image.dart';
import 'post_image_carousel.dart';
import 'comment_tree_sheet.dart';
import '../providers/post_store_provider.dart';
import '../services/navigation_service.dart';
import 'likes_bottom_sheet.dart';
import 'post_options_bottom_sheet.dart';
import '../providers/auth_provider.dart';

/// PostCard para el contexto comunitario (Home).
///
/// REGLAS:
///   - Sin price labels.
///   - Sin lógica de artículos (isArticle, priceLabel).
///   - Sin tabs ni categorías globales.
///   - Solo texto e imagen social.
class CommunityPostCard extends StatefulWidget {
  final PostModel post;

  const CommunityPostCard({super.key, required this.post});

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  PostModel get post => widget.post;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NavigationService.instance.registerPostKey(post.id, _cardKey);
  }

  @override
  void dispose() {
    NavigationService.instance.unregisterPostKey(post.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _cardKey,
      child: post.hasImage ? _buildImagePost(context) : _buildTextPost(context),
    );
  }

  Widget _buildImagePost(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceContainerHighest, width: 1),
          top: BorderSide(color: AppTheme.surfaceContainerHighest, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _AuthorAvatar(
                    imageUrl: post.authorImageUrl, name: post.authorUsername),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (post.networkName.isNotEmpty)
                        Text(
                          post.networkName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PostOptionsBottomSheet(post: post),
                  ),
                  child: const Icon(Icons.more_horiz,
                      color: AppTheme.onSurfaceVariant, size: 20),
                ),
              ],
            ),
          ),

          // ── Imagen ────────────────────────────────────────────────────────
          PostImageCarousel(mediaUrls: post.mediaUrls),

          // ── Acciones ──────────────────────────────────────────────────────
          _buildActions(context),

          // ── Contenido ─────────────────────────────────────────────────────
          if (post.displayContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: _PostContentImage(post: post),
            ),

          // ── Tiempo ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              post.timeAgo,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPost(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorAvatar(
                  imageUrl: post.authorImageUrl, name: post.authorUsername),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.networkName.isNotEmpty)
                      Text(
                        post.networkName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      post.timeAgo,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PostOptionsBottomSheet(post: post),
                ),
                child: const Icon(Icons.more_horiz,
                    color: AppTheme.onSurfaceVariant, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Título (sin price label) ───────────────────────────────────────
          if (post.titulo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                post.titulo,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ),

          // ── Contenido ─────────────────────────────────────────────────────
          if (post.displayContent.isNotEmpty)
            _PostContentText(post: post),

          const SizedBox(height: 12),

          // ── Acciones ──────────────────────────────────────────────────────
          _buildActions(context, padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, {EdgeInsetsGeometry? padding}) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isAuthor = currentUserId != null && currentUserId == post.authorId;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.read<CommandBus>().dispatch(ToggleLikeCommand(postId: post.id)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                post.liked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(post.liked),
                color: post.liked ? AppTheme.primary : AppTheme.onSurfaceVariant,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => LikesBottomSheet(postId: post.id),
            ),
            child: Text(
              '${post.likesCount}',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CommentTreeSheet(postId: post.id),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppTheme.onSurfaceVariant, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${post.commentsCount}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isAuthor)
            GestureDetector(
              onTap: () => context.read<CommandBus>().dispatch(ToggleSaveCommand(postId: post.id)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  post.saved ? Icons.bookmark : Icons.bookmark_border,
                  key: ValueKey(post.saved),
                  color: post.saved ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  size: 26,
                ),
              ),
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

// ─── Contenido en post de imagen ──────────────────────────────────────────────
class _PostContentImage extends StatefulWidget {
  final PostModel post;
  const _PostContentImage({required this.post});

  @override
  State<_PostContentImage> createState() => _PostContentImageState();
}

class _PostContentImageState extends State<_PostContentImage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.post.displayContent;
    if (text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
            children: [
              TextSpan(
                text: widget.post.authorUsername,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(text: text),
            ],
          ),
          maxLines: _expanded ? null : 2,
          overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (!_expanded && text.length > 80)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Ver más',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Contenido en post de texto ───────────────────────────────────────────────
class _PostContentText extends StatefulWidget {
  final PostModel post;
  const _PostContentText({required this.post});

  @override
  State<_PostContentText> createState() => _PostContentTextState();
}

class _PostContentTextState extends State<_PostContentText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.post.displayContent;
    if (text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
              fontSize: 15, color: AppTheme.onSurface, height: 1.4),
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (!_expanded && text.length > 180)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ver más',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
