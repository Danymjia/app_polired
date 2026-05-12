import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post.authorImageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const CircleAvatar(radius: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          post.authorUsername,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.more_horiz,
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Image
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              color: AppTheme.surfaceContainer,
              width: double.infinity,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.favorite_border, size: 26),
                        SizedBox(width: 16),
                        Icon(Icons.chat_bubble_outline, size: 26),
                        SizedBox(width: 16),
                        Icon(Icons.send, size: 26),
                      ],
                    ),
                    const Icon(Icons.bookmark_border, size: 26),
                  ],
                ),
                const SizedBox(height: 8),

                // Likes
                Text(
                  '${post.likesCount} Me gusta',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Content
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurface,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: '${post.authorUsername} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: post.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Comments
                Text(
                  'Ver los ${post.commentsCount} comentarios',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // Time ago
                Text(
                  post.timeAgo,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
