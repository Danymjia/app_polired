import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/post_store_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/core/base_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<String> _postIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
  }

  Future<void> _fetchSavedPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postService = context.read<PostService>();
      final result = await postService.fetchSavedPosts();

      if (result.success && result.data != null) {
        final posts = result.data!;
        if (mounted) {
          // Ingest into central post store to unify state
          if (posts.isNotEmpty) {
            context.read<PostStoreProvider>().addBatchPosts(posts);
          }
          setState(() {
            _postIds = posts.map((p) => p.id).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result.message ?? 'Error al cargar guardados';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión al cargar guardados';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically filter active saves using central store (Optimistic Delete reactiveness)
    final store = context.watch<PostStoreProvider>();
    final activeSavedPostIds = _postIds.where((id) {
      final post = store.getPost(id);
      return post != null && post.saved;
    }).toList();

    return BaseScreen(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Guardados',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSavedPosts,
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        child: _buildContent(activeSavedPostIds),
      ),
    );
  }

  Widget _buildContent(List<String> activeSavedPostIds) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSavedPosts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(120, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Reintentar', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (activeSavedPostIds.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_outline,
                      size: 32,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes publicaciones guardadas',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las publicaciones que guardes aparecerán aquí.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: activeSavedPostIds.length + 1,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        if (index == activeSavedPostIds.length) {
          return SizedBox(
            height: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
          );
        }
        final postId = activeSavedPostIds[index];
        return Builder(
          builder: (context) {
            final post = context.select<PostStoreProvider, PostModel?>(
              (store) => store.getPost(postId),
            );
            if (post == null) return const SizedBox.shrink();
            return PostCard(post: post);
          },
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 180,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 48,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
