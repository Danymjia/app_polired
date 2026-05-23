import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/post_store_provider.dart';
import '../../widgets/post_card.dart';
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          PostCard(post: post),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
