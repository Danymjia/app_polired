import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/network_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../services/command_bus.dart';
import '../../widgets/post_options_bottom_sheet.dart';
import '../../providers/feed_provider.dart';
import '../../models/commands/feed_command.dart';
import '../../models/feed_context.dart';
import '../../models/post_model.dart';
import '../../services/navigation_service.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/community_post_card.dart';
import '../notifications/notifications_screen.dart';
import '../post/add_post_screen.dart';
import '../map/map_screen.dart';

/// Pantalla de Feed Principal — SOLO publicaciones comunitarias.
///
/// REGLAS ARQUITECTÓNICAS:
///   - Usa ÚNICAMENTE [NetworkProvider] como fuente de IDs.
///   - Posts resueltos en BATCH vía [PostStoreProvider.resolvePosts].
///   - Sin fallback, sin categorías globales, sin mezcla.
///   - Scroll infinito → [NetworkProvider.loadMoreForNetwork].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    NavigationService.instance.register(FeedContext.home(), _scrollController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final store = context.read<PostStoreProvider>();
          if (!store.isSocialStateInitialized) {
            final commandBus = context.read<CommandBus>();
            commandBus.dispatch(InitializeSocialStateCommand());
          }
        }
      });
    }
  }

  @override
  void dispose() {
    NavigationService.instance.unregister(FeedContext.home());
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<NetworkProvider>();
    if (!_scrollController.hasClients ||
        provider.isLoadingMoreFeed ||
        !provider.hasMoreFeed) {
      return;
    }
    if (_scrollController.position.extentAfter < 240) {
      provider.loadMoreForNetwork();
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final joinedNetworks =
        networkProvider.networkStories.where((n) => n.isJoined).toList();

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
                icon: const Icon(Icons.add, color: AppTheme.primaryText, size: 28),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPostScreen()),
                ),
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
                  icon: const Icon(Icons.map_outlined,
                      color: AppTheme.primaryText, size: 28),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/images/owl_icon.png',
                    width: 26,
                    height: 26,
                    color: AppTheme.primaryText,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryText,
                      size: 26,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await networkProvider.loadStudentNetworks();
          if (networkProvider.selectedNetwork != null) {
            await networkProvider.refreshHomeFeed();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight),
            ),
            SliverToBoxAdapter(
              child: _NetworkStoriesSection(provider: networkProvider),
            ),
            ..._buildFeedContent(context, networkProvider, joinedNetworks),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedContent(
    BuildContext context,
    NetworkProvider networkProvider,
    List<dynamic> joinedNetworks,
  ) {
    // ── Cargando redes ────────────────────────────────────────────────────────
    if (networkProvider.isLoading && networkProvider.networkStories.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ];
    }

    // ── Sin redes unidas ──────────────────────────────────────────────────────
    if (joinedNetworks.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_add_outlined,
                      size: 72,
                      color:
                          AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 20),
                  Text('Sin redes aún', style: AppTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a una comunidad para ver\nsus publicaciones aquí.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // ── Cargando feed inicial ─────────────────────────────────────────────────
    final String currentNetworkId = networkProvider.selectedNetwork?.id ?? '';
    final posts = currentNetworkId.isNotEmpty 
        ? FeedProvider.watchFeed(context, FeedContext.home(communityId: currentNetworkId))
        : <PostModel>[];

    if (networkProvider.isLoadingInitialFeed && posts.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ];
    }

    // ── Error ─────────────────────────────────────────────────────────────────
    if (networkProvider.feedStatus == FeedStatus.error && posts.isEmpty) {
      return [
        SliverFillRemaining(
          child: _ErrorState(
            message: networkProvider.feedErrorState ??
                networkProvider.homeFeedError ??
                'Error al cargar el feed',
            onRetry: networkProvider.refreshHomeFeed,
          ),
        ),
      ];
    }

    // ── Feed vacío ────────────────────────────────────────────────────────────
    if (posts.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'No hay publicaciones en esta red aún.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    // ── Feed con datos — Reactivo a través de FeedProvider ────────────────
    return [
      _HomeFeedBatchList(posts: posts),
      if (networkProvider.isLoadingMoreFeed)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primary)),
          ),
        ),
      if (!networkProvider.hasMoreFeed && posts.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'Ya viste todo en esta red',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.onSurface.withAlpha(150)),
              ),
            ),
          ),
        ),
    ];
  }
}

// ─── Batch Feed List ──────────────────────────────────────────────────────────
/// Resuelve TODOS los postIds en un único selector para evitar O(n) selects.
///
/// ✅ Regla: UI no resuelve PostModel individualmente en itemBuilder.
/// ✅ El selector se memoiza — solo rebuild si el mapa del store cambia.
class _HomeFeedBatchList extends StatelessWidget {
  final List<PostModel> posts;
  const _HomeFeedBatchList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final isLast = index == posts.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 80.0 : 0),
            child: CommunityPostCard(
              key: ValueKey(posts[index].id),
              post: posts[index],
            ),
          );
        },
        childCount: posts.length,
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
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: provider.networkStories.map((network) {
                  final isSelected =
                      provider.selectedNetwork?.id == network.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: NetworkAvatar(
                      network: network,
                      isSelected: isSelected,
                      onTap: () {
                        if (!network.isJoined) {
                          context
                              .push('/explore/networks/${network.id}')
                              .then((_) {
                            provider.pendingAutoSelectNetworkId = network.id;
                            provider.loadStudentNetworks();
                          });
                        } else {
                          if (isSelected) {
                            context.push('/explore/networks/${network.id}');
                          } else {
                            provider.selectNetwork(network);
                          }
                        }
                      },
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
            const Icon(Icons.cloud_off_outlined,
                size: 72, color: AppTheme.error),
            const SizedBox(height: 20),
            Text('Algo salió mal', style: AppTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(message,
                style: AppTheme.bodyMedium, textAlign: TextAlign.center),
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
