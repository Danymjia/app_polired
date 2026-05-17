import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/global_feed_provider.dart';
import '../../models/post_model.dart';
import 'widgets/explore_empty_state.dart';
import 'widgets/explore_error_state.dart';
import 'widgets/explore_header.dart';
import 'widgets/explore_loading.dart';
import 'widgets/explore_post_card.dart';
import 'widgets/explore_tabs.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ScrollController _scrollController;
  bool _initialized = false;
  int _selectedTab = 0;
  final List<String> _tabs = ['Noticias', 'Marketplace', 'Cursos'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<GlobalFeedProvider>().loadInitial(
        category: _tabs[_selectedTab].toLowerCase(),
      );
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
    final provider = context.read<GlobalFeedProvider>();
    if (!_scrollController.hasClients ||
        provider.isLoadingMore ||
        !provider.hasMore) {
      return;
    }
    if (_scrollController.position.extentAfter < 220) {
      provider.loadMore();
    }
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    context.read<GlobalFeedProvider>().setCategory(_tabs[index].toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlobalFeedProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => provider.refreshFeed(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _ExploreHeaderDelegate(),
            ),
            ExploreTabs(
              selectedIndex: _selectedTab,
              tabs: _tabs,
              onTabSelected: _onTabSelected,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  _tabs[_selectedTab],
                  style: AppTheme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (provider.isLoadingInitial && provider.posts.isEmpty)
              const ExploreLoading()
            else if (provider.errorMessage != null && provider.posts.isEmpty)
              SliverFillRemaining(
                child: ExploreErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => provider.loadInitial(
                    category: _tabs[_selectedTab].toLowerCase(),
                  ),
                ),
              )
            else if (provider.posts.isEmpty)
              const SliverFillRemaining(child: ExploreEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final PostModel post = provider.posts[index];
                  return ExplorePostCard(post: post);
                }, childCount: provider.posts.length),
              ),
            if (provider.isLoadingMore)
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
            if (!provider.hasMore && provider.posts.isNotEmpty)
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
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
          ],
        ),
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
