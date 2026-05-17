import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/post_model.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/post_image_carousel.dart';

class ExplorePostCard extends StatelessWidget {
  final PostModel post;

  const ExplorePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.surfaceContainerHigh.withAlpha(179),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AuthorAvatar(imageUrl: post.authorImageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.authorUsername.isNotEmpty
                                    ? post.authorUsername
                                    : 'Usuario',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.authorId.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(31),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Verificado',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.timeAgo,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.onSurface.withAlpha(153),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.more_horiz,
                      color: AppTheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            if (post.hasImage)
              PostImageCarousel(
                mediaUrls: post.mediaUrls,
                height: 280,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.circular(AppTheme.radiusXl),
                  bottomRight: Radius.circular(AppTheme.radiusXl),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.radiusXl),
                    bottomRight: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Text(
                  post.contenido.isNotEmpty ? post.contenido : post.titulo,
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurface),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PostAction(icon: Icons.favorite_border),
                      const SizedBox(width: 16),
                      _PostAction(icon: Icons.mode_comment_outlined),
                      const SizedBox(width: 16),
                      _PostAction(icon: Icons.send_outlined),
                      const Spacer(),
                      _PostAction(icon: Icons.bookmark_border),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${post.likesCount} Me gusta',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${post.authorUsername.isNotEmpty ? post.authorUsername : 'Usuario'} ',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: post.contenido.isNotEmpty
                              ? post.contenido
                              : post.titulo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ver comentarios (${post.commentsCount})',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.onSurface.withAlpha(166),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? imageUrl;

  const _AuthorAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? SafeNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorWidget: Icon(
                Icons.person,
                color: AppTheme.onSurface.withAlpha(153),
                size: 28,
              ),
            )
          : Icon(
              Icons.person,
              color: AppTheme.onSurface.withAlpha(153),
              size: 28,
            ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;

  const _PostAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 24, color: AppTheme.onSurface.withAlpha(209)),
        ),
      ),
    );
  }
}
