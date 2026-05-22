import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../post/add_post_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/my_profile_feed_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/public_profile_grid.dart';

/// Pantalla de Perfil de Usuario — diseño estilo Instagram/Threads minimalista.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkProvider>().fetchRedesDelEstudiante();
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<MyProfileFeedProvider>().fetchInitialFeed(user.id);
      }
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
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<MyProfileFeedProvider>().fetchMoreFeed(user.id);
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String nombre, String apellido) {
    String out = '';
    if (nombre.isNotEmpty) out += nombre[0].toUpperCase();
    if (apellido.isNotEmpty) out += apellido[0].toUpperCase();
    return out;
  }

  Widget _buildAvatar(String? url, String initials) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(43),
        child: url != null && url.isNotEmpty
            ? SafeNetworkImage(
                url: url,
                fit: BoxFit.cover,
                errorWidget: _buildInitialsWidget(initials),
              )
            : _buildInitialsWidget(initials),
      ),
    );
  }

  Widget _buildInitialsWidget(String initials) {
    return Container(
      color: AppTheme.primaryText,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final redesCount = context.watch<NetworkProvider>().redesCount;
    final redesList = context.watch<NetworkProvider>().redes;
    final bioDescripcion = user?.biografia?.trim();
    final initials = _initials(user?.nombre ?? '', user?.apellido ?? '');
    final isAdmin = user?.esAdminRed ?? false;

    final myProfileFeedProvider = context.watch<MyProfileFeedProvider>();
    final postStore = context.watch<PostStoreProvider>();

    final allIds = myProfileFeedProvider.postIds;
    final publicationIds = allIds.where((id) {
      final post = postStore.getPost(id);
      return post != null && !post.isArticle;
    }).toList();

    final articleIds = allIds.where((id) {
      final post = postStore.getPost(id);
      return post != null && post.isArticle;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            final myFeed = context.read<MyProfileFeedProvider>();
            final netProv = context.read<NetworkProvider>();
            await myFeed.fetchInitialFeed(user.id);
            await netProv.fetchRedesDelEstudiante();
          }
        },
        color: AppTheme.primary,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: AppTheme.surfaceContainerLowest,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primaryText, size: 26),
                  tooltip: 'Nueva publicación',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPostScreen()),
                    );
                  },
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: AppTheme.primaryText),
                    const SizedBox(width: 4),
                    Text(
                      user?.username ?? 'Perfil',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppTheme.primaryText, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: avatar | name + stats
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAvatar(user?.fotoPerfil, initials),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.nombreCompleto ?? 'Cargando...',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildStat(
                                      user?.publicacionesCount.toString() ?? '0',
                                      'Publicaciones',
                                    ),
                                    const SizedBox(width: 28),
                                    _buildStat(
                                      redesCount?.toString() ?? '0',
                                      'Redes',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Bio
                      if (bioDescripcion != null && bioDescripcion.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          bioDescripcion,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.45,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ],

                      // Networks list (horizontal scroll, only name)
                      if (redesList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Redes comunitarias',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: redesList.length,
                            itemBuilder: (context, index) {
                              final net = redesList[index];
                              final netId = net['_id'] ?? '';
                              final netNombre = net['nombre'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  onPressed: () {
                                    if (netId.isNotEmpty) {
                                      context.push('/explore/networks/$netId');
                                    }
                                  },
                                  label: Text(
                                    netNombre,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.surfaceContainerLow,
                                  side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceContainerLow,
                                  foregroundColor: AppTheme.primaryText,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Editar perfil',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Gestión de red: próximamente'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Gestionar red',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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
          body: myProfileFeedProvider.isLoadingFeed && allIds.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : myProfileFeedProvider.feedError != null && allIds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            myProfileFeedProvider.feedError ?? 'Error al cargar feed',
                            style: GoogleFonts.inter(color: AppTheme.error, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (user != null) {
                                myProfileFeedProvider.fetchInitialFeed(user.id);
                              }
                            },
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
                          key: const PageStorageKey('my-publications-scroll'),
                          slivers: [
                            PublicProfileGrid(
                              postIds: publicationIds,
                              scrollController: _scrollController,
                              isFetchingMore: myProfileFeedProvider.isLoadingMoreFeed,
                            ),
                          ],
                        ),
                        CustomScrollView(
                          key: const PageStorageKey('my-articles-scroll'),
                          slivers: [
                            PublicProfileGrid(
                              postIds: articleIds,
                              scrollController: _scrollController,
                              isFetchingMore: myProfileFeedProvider.isLoadingMoreFeed,
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
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
      color: AppTheme.surfaceContainerLowest,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
