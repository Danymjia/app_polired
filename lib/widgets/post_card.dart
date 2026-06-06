import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import 'package:provider/provider.dart';
import '../../services/command_bus.dart';
import '../../models/commands/feed_command.dart';
import 'safe_network_image.dart';
import 'post_image_carousel.dart';
import 'comment_tree_sheet.dart';
import 'likes_bottom_sheet.dart';
import 'post_options_bottom_sheet.dart';
import '../providers/auth_provider.dart';
import '../providers/post_store_provider.dart';

/// Responsabilidad principal:
/// Renderizar una tarjeta de publicación para el feed Home (Mi Red). Soporta contenido mixto (texto o imágenes).
///
/// Flujo dentro de la app:
/// Actúa como un suscriptor de CQRS local. Recibe un `PostModel` base como parámetro, pero se envuelve en `context.select<PostStoreProvider>` para escuchar mutaciones (likes, deletes) en tiempo real sin reconstruir toda la lista (List View).
///
/// Dependencias críticas:
/// - `PostStoreProvider` (Caché local de entidades).
/// - `CommandBus` (Despacho de `ToggleLikeCommand` y `ToggleSaveCommand`).
///
/// Side Effects:
/// - Renderizado Aislado: El redibujado se auto-limita a este nodo en el árbol de widgets.
///
/// Recordatorios técnicos y CQRS:
/// - Interfaz Optimista: Los botones de interacción NO bloquean el UI ni esperan al Backend. Despachan un Comando y asumen que `PostStoreProvider` actualizará el estado instantáneamente.
class PostCard extends StatefulWidget {
  final PostModel post;

  final bool enableNetworkNavigation;

  const PostCard({super.key, required this.post, this.enableNetworkNavigation = true});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {

  @override
  Widget build(BuildContext context) {
    final currentPost = context.select<PostStoreProvider, PostModel>(
      (s) => s.getPost(widget.post.id) ?? widget.post,
    );
    if (currentPost.hasImage) {
      return _buildImagePost(context, currentPost);
    } else {
      return _buildTextPost(context, currentPost);
    }
  }

  Widget _buildSubtitle(PostModel post) {
    String subtitle = '';
    if (post.networkName.isNotEmpty) {
      subtitle = post.networkName;
    } else if (post.categoria.isNotEmpty) {
      String cat = post.categoria;
      if (cat.toLowerCase() == 'venta') {
        subtitle = 'Ventas';
      } else if (cat.toLowerCase() == 'cursos') {
        subtitle = 'Cursos';
      } else if (cat.toLowerCase() == 'noticias') {
        subtitle = 'Noticias';
      } else {
        subtitle = cat[0].toUpperCase() + cat.substring(1).toLowerCase();
      }
    }

    if (subtitle.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {

        if (widget.enableNetworkNavigation && post.networkName.isNotEmpty && post.networkId.isNotEmpty) {
          context.push('/explore/networks/${post.networkId}');
        }
      },
      child: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppTheme.primary.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImagePost(BuildContext context, PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.surfaceContainerHighest,
            width: 1,
          ),
          top: BorderSide(
            color: AppTheme.surfaceContainerHighest,
            width: 1,
          ),
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
                GestureDetector(
                  onTap: () => context.push('/explore/public-profile/${post.authorId}'),
                  child: _AuthorAvatar(
                    imageUrl: post.authorImageUrl,
                    name: post.authorUsername,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/explore/public-profile/${post.authorId}'),
                        child: Text(
                          post.authorUsername,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildSubtitle(post),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PostOptionsBottomSheet(post: post),
                    );
                  },
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // ── Imagen ────────────────────────────────────────────────────────
          Stack(
            children: [
              PostImageCarousel(
                mediaUrls: post.mediaUrls,
                aspectRatio: post.aspectRatio,
                onDoubleTap: () {
                  if (!post.liked) {
                    context.read<CommandBus>().dispatch(ToggleLikeCommand(postId: post.id));
                  }
                },
              ),
              if (post.isArticle && post.priceLabel.isNotEmpty)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.priceLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Acciones ────────────────────────────────────────────────────────
          _buildActions(context, post),

          // ── Contenido ───────────────────────────────────────────────────────
          if (post.displayContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: _PostContentImage(post: post),
            ),

          // ── Tiempo ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              post.timeAgo,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPost(BuildContext context, PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/explore/public-profile/${post.authorId}'),
                child: _AuthorAvatar(
                  imageUrl: post.authorImageUrl,
                  name: post.authorUsername,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/explore/public-profile/${post.authorId}'),
                      child: Text(
                        post.authorUsername,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildSubtitle(post),
                    Text(
                      post.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PostOptionsBottomSheet(post: post),
                  );
                },
                child: const Icon(
                  Icons.more_horiz,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Título y Precio ──────────────────────────────────────────────────
          if (post.titulo.isNotEmpty || (post.isArticle && post.priceLabel.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.titulo.isNotEmpty)
                    Expanded(
                      child: Text(
                        post.titulo,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                  if (post.titulo.isNotEmpty && post.isArticle && post.priceLabel.isNotEmpty)
                    const SizedBox(width: 8),
                  if (post.isArticle && post.priceLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post.priceLabel,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Contenido ───────────────────────────────────────────────────────
          if (post.displayContent.isNotEmpty)
            _PostContentText(post: post),

          const SizedBox(height: 12),

          // ── Acciones ────────────────────────────────────────────────────────
          _buildActions(context, post, padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, PostModel post, {EdgeInsetsGeometry? padding}) {
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
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (_) => LikesBottomSheet(postId: post.id),
              );
            },
            child: Text(
              '${post.likesCount}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentTreeSheet(postId: post.id),
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.commentsCount}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
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

// ─── Contenido Textual (Imagen) ───────────────────────────────────────────────
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
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(text: text),
            ],
          ),
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Contenido Textual (Solo Texto) ───────────────────────────────────────────
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
            fontSize: 15,
            color: AppTheme.onSurface,
            height: 1.4,
          ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
