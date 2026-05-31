import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/post_store_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/core/base_screen.dart';

class LikedPostsScreen extends StatefulWidget {
  const LikedPostsScreen({super.key});

  @override
  State<LikedPostsScreen> createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<String> _postIds = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLikedPosts(isInitial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchLikedPosts(isInitial: false);
    }
  }

  Future<void> _fetchLikedPosts({required bool isInitial}) async {
    if (isInitial) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
        _postIds = [];
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      if (!mounted) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final postService = context.read<PostService>();
      final result = await postService.fetchLikedPosts(page: _currentPage, limit: _limit);

      if (result.success && result.data != null) {
        final posts = result.data!;
        if (mounted) {
          // Ingest into central post store to unify state
          context.read<PostStoreProvider>().addBatchPosts(posts);
          
          final newIds = posts.map((p) => p.id).toList();
          setState(() {
            if (isInitial) {
              _postIds = newIds;
            } else {
              // Add only new IDs to avoid duplicates
              final uniqueNewIds = newIds.where((id) => !_postIds.contains(id)).toList();
              _postIds.addAll(uniqueNewIds);
            }
            
            _currentPage++;
            _isLoading = false;
            _isLoadingMore = false;
            // If the number of items fetched is less than limit, we reached the end
            if (posts.length < _limit) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = isInitial ? (result.message ?? 'Error al cargar likes') : null;
            _isLoading = false;
            _isLoadingMore = false;
          });
          if (!isInitial) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Error al cargar más publicaciones')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = isInitial ? 'Error de conexión al cargar likes' : null;
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (!isInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión al cargar más publicaciones')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Me gusta',
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
        onRefresh: () => _fetchLikedPosts(isInitial: true),
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
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
                    onPressed: () => _fetchLikedPosts(isInitial: true),
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

    final store = context.watch<PostStoreProvider>();
    final activeLikedPostIds = _postIds.where((id) {
      final post = store.getPost(id);
      return post != null && post.liked;
    }).toList();

    if (activeLikedPostIds.isEmpty) {
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
                      Icons.favorite_border,
                      size: 32,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes publicaciones con me gusta',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las publicaciones a las que des me gusta aparecerán aquí.',
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
      controller: _scrollController,
      itemCount: activeLikedPostIds.length + (_hasMore ? 1 : 0) + 1,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        if (index == activeLikedPostIds.length + (_hasMore ? 1 : 0)) {
          return SizedBox(
            height: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
          );
        }

        if (index == activeLikedPostIds.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
              ),
            ),
          );
        }

        final postId = activeLikedPostIds[index];
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
