import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/community_feed_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/post_card.dart';
import '../notifications/notifications_screen.dart';
import '../post/add_post_screen.dart';

/// Pantalla de Feed Principal.
/// Consume publicaciones reales desde el backend vía [CommunityFeedProvider].
/// Soporta: loading, empty, error, pull-to-refresh y scroll infinito.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<CommunityFeedProvider>().loadInitial();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<CommunityFeedProvider>();
    if (!_scrollController.hasClients || provider.isLoadingMore || !provider.hasMore) return;
    if (_scrollController.position.extentAfter < 240) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final communityProvider = context.watch<CommunityFeedProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: AppTheme.surface.withValues(alpha: 0.85),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.add_box_outlined, color: AppTheme.primaryText, size: 28),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen()));
                },
              ),
              title: Text(
                'Polired',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppTheme.primaryText, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/images/owl_icon.png',
                    width: 26,
                    height: 26,
                    color: AppTheme.primaryText,
                    errorBuilder: (context, error, stack) => const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryText,
                      size: 26,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => communityProvider.refreshFeed(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Spacer para el AppBar translúcido
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            ),

            // ── Network Stories Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _NetworkStoriesSection(provider: networkProvider),
            ),

            // ── Feed Content ────────────────────────────────────────────────
            if (communityProvider.isLoadingInitial && communityProvider.postIds.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (communityProvider.errorMessage != null && communityProvider.postIds.isEmpty)
              SliverFillRemaining(
                child: _ErrorState(
                  message: communityProvider.errorMessage!,
                  onRetry: () => communityProvider.loadInitial(),
                ),
              )
            else if (communityProvider.postIds.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No hay publicaciones comunitarias aún.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final postId = communityProvider.postIds[index];
                    final isLast = index == communityProvider.postIds.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 80.0 : 0),
                      child: Builder(
                        builder: (context) {
                          final post = context.select<PostStoreProvider, PostModel?>(
                            (store) => store.getPost(postId)
                          );
                          if (post == null) return const SizedBox.shrink();
                          return PostCard(post: post);
                        },
                      ),
                    );
                  },
                  childCount: communityProvider.postIds.length,
                ),
              ),
            if (communityProvider.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
              ),
            if (!communityProvider.hasMore && communityProvider.postIds.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Text('Ya no hay más publicaciones comunitarias')), 
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stories Section ──────────────────────────────────────────────────────────
class _NetworkStoriesSection extends StatelessWidget {
  final NetworkProvider provider;
  const _NetworkStoriesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.networkStories.isEmpty && !provider.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: provider.isLoading && provider.networkStories.isEmpty
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: provider.networkStories.map((network) {
                  final isSelected = provider.selectedNetwork?.id == network.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: NetworkAvatar(
                      network: network,
                      isSelected: isSelected,
                      onTap: () {},
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 72, color: AppTheme.error),
            const SizedBox(height: 20),
            Text('Algo salió mal', style: AppTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
