import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/global_feed_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../providers/feed_provider.dart';
import '../../models/feed_context.dart';
import '../../models/post_model.dart';
import '../../models/events/post_event.dart';
import '../../services/navigation_service.dart';
import '../../services/navigation_bus.dart';
import 'widgets/explore_empty_state.dart';
import 'widgets/explore_error_state.dart';
import 'widgets/explore_header.dart';
import 'widgets/explore_loading.dart';
import '../../widgets/global_post_card.dart';
import 'widgets/explore_tabs.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  bool _initialized = false;
  int _selectedTab = 0;
  final List<String> _tabs = ['Noticias', 'Marketplace', 'Cursos'];

  // Un ScrollController por cada tab para mantener posiciones y permitir scroll to top independiente
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabs.length; i++) {
      _scrollControllers[i] = ScrollController();
      NavigationService.instance.register(
        FeedContext.exploreTab(categoryId: _tabs[i].toLowerCase()),
        _scrollControllers[i]!,
      );
    }
    NavigationService.instance.register(FeedContext.exploreGlobal(), _scrollControllers[0]!);

    final bus = context.read<NavigationBus>();
    bus.stream.listen((event) {
      if (event is FocusPostEvent && mounted) {
        if (event.context.type == ContextType.exploreTab) {
          final targetCategory = event.context.categoryId?.toLowerCase() ?? '';
          final targetIndex = _tabs.indexWhere((t) {
            String tabName = t.toLowerCase();
            if (tabName == 'marketplace') tabName = 'venta';
            return tabName == targetCategory;
          });
          if (targetIndex != -1 && targetIndex != _selectedTab) {
            _onTabSelected(targetIndex);
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GlobalFeedProvider>().loadInitial(
            category: _tabs[_selectedTab].toLowerCase(),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < _tabs.length; i++) {
      NavigationService.instance.unregister(FeedContext.exploreTab(categoryId: _tabs[i].toLowerCase()));
    }
    NavigationService.instance.unregister(FeedContext.exploreGlobal());
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void scrollToTop() {
    final controller = _scrollControllers[_selectedTab];
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) {
      // Re-click: scroll to top
      scrollToTop();
      return;
    }
    setState(() => _selectedTab = index);
    context.read<GlobalFeedProvider>().setCategory(_tabs[index].toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ExploreHeader(),
            ExploreTabs(
              selectedIndex: _selectedTab,
              tabs: _tabs,
              onTabSelected: _onTabSelected,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: List.generate(_tabs.length, (index) {
                  return ExploreFeedList(
                    category: _tabs[index],
                    scrollController: _scrollControllers[index]!,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreFeedList extends StatefulWidget {
  final String category;
  final ScrollController scrollController;

  const ExploreFeedList({
    super.key,
    required this.category,
    required this.scrollController,
  });

  @override
  State<ExploreFeedList> createState() => _ExploreFeedListState();
}

class _ExploreFeedListState extends State<ExploreFeedList>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<GlobalFeedProvider>();
    if (provider.selectedCategory != widget.category.toLowerCase()) return;
    
    if (!widget.scrollController.hasClients ||
        provider.isLoadingMore ||
        !provider.hasMore) {
      return;
    }
    if (widget.scrollController.position.extentAfter < 220) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<GlobalFeedProvider>();
    return _buildListContent(provider);
  }

  Widget _buildListContent(GlobalFeedProvider provider) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        if (provider.selectedCategory == widget.category.toLowerCase()) {
          await provider.refreshFeed();
        }
      },
      child: CustomScrollView(
        key: PageStorageKey('explore_${widget.category}'),
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                widget.category,
                style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          _CategoryFeedBuilder(category: widget.category.toLowerCase()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _CategoryFeedBuilder extends StatelessWidget {
  final String category;
  const _CategoryFeedBuilder({required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlobalFeedProvider>();
    
    final CategoryState state = provider.getCategoryState(category);
    final posts = FeedProvider.watchFeed(context, FeedContext.exploreTab(categoryId: category));

    final bool isLoadingInitial = state.isLoadingInitial;
    final bool isLoadingMore = state.isLoadingMore;
    final bool hasMore = state.hasMore;
    final String? errorMessage = state.errorMessage;

    if (isLoadingInitial && posts.isEmpty) {
      return const ExploreLoading();
    } else if (errorMessage != null && posts.isEmpty) {
      return SliverFillRemaining(
        child: ExploreErrorState(
          message: errorMessage,
          onRetry: () => provider.loadInitial(category: category),
        ),
      );
    } else if (posts.isEmpty) {
      return const SliverFillRemaining(child: ExploreEmptyState());
    }

    return SliverMainAxisGroup(
      slivers: [
        _GlobalFeedBatchList(posts: posts),
        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        if (!hasMore && posts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Has alcanzado el final del feed',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.onSurface.withAlpha(179),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlobalFeedBatchList extends StatelessWidget {
  final List<PostModel> posts;
  const _GlobalFeedBatchList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];
          return GlobalPostCard(
            key: ValueKey(post.id),
            post: post,
          );
        },
        childCount: posts.length,
      ),
    );
  }
}

class _ExploreHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return kToolbarHeight + view.padding.top / view.devicePixelRatio;
  }

  @override
  double get maxExtent {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return kToolbarHeight + view.padding.top / view.devicePixelRatio;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const ExploreHeader();
  }

  @override
  bool shouldRebuild(covariant _ExploreHeaderDelegate oldDelegate) => false;
}
