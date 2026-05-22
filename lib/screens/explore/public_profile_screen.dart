import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/public_profile_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../widgets/public_profile_header.dart';
import '../../widgets/public_profile_grid.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicProfileProvider>();
      provider.setCurrentUser(widget.userId);
      provider.fetchProfileInfo();
      provider.fetchInitialFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<PublicProfileProvider>().fetchMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer2<PublicProfileProvider, PostStoreProvider>(
        builder: (context, profileProvider, postStore, child) {
          final info = profileProvider.currentInfo;

          if (profileProvider.isLoadingInfo && info == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            );
          }

          if (profileProvider.infoError != null && info == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileProvider.infoError ?? 'Error al cargar perfil',
                      style: GoogleFonts.inter(color: AppTheme.error, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        profileProvider.fetchProfileInfo();
                        profileProvider.fetchInitialFeed();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allIds = profileProvider.currentPostIds;
          
          final publicationIds = allIds.where((id) {
            final post = postStore.getPost(id);
            return post != null && !post.isArticle;
          }).toList();

          final articleIds = allIds.where((id) {
            final post = postStore.getPost(id);
            return post != null && post.isArticle;
          }).toList();

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.onSurface, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  title: Text(
                    info != null ? '@${info.username}' : 'Perfil',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.onSurface, size: 24),
                      onPressed: () {}, // Only UI for now
                    ),
                  ],
                ),
                if (info != null)
                  SliverToBoxAdapter(
                    child: PublicProfileHeader(profile: info),
                  ),
                SliverToBoxAdapter(
                  child: Divider(height: 1, thickness: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: AppTheme.onSurfaceVariant,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.grid_on_rounded, size: 20),
                          text: 'Publicaciones',
                        ),
                        Tab(
                          icon: Icon(Icons.shopping_bag_rounded, size: 20),
                          text: 'Artículos',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: profileProvider.isLoadingFeed && allIds.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : profileProvider.feedError != null && allIds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profileProvider.feedError ?? 'Error al cargar feed',
                              style: GoogleFonts.inter(color: AppTheme.error, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => profileProvider.fetchInitialFeed(),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          CustomScrollView(
                            key: const PageStorageKey('publications-scroll'),
                            slivers: [
                              PublicProfileGrid(
                                postIds: publicationIds,
                                scrollController: _scrollController,
                                isFetchingMore: profileProvider.isLoadingMoreFeed,
                              ),
                            ],
                          ),
                          CustomScrollView(
                            key: const PageStorageKey('articles-scroll'),
                            slivers: [
                              PublicProfileGrid(
                                postIds: articleIds,
                                scrollController: _scrollController,
                                isFetchingMore: profileProvider.isLoadingMoreFeed,
                              ),
                            ],
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
