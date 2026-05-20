import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/explore_networks_provider.dart';
import '../../providers/explore_users_provider.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/user_search_tile.dart';

class ExploreNetworksScreen extends StatefulWidget {
  const ExploreNetworksScreen({super.key});

  @override
  State<ExploreNetworksScreen> createState() => _ExploreNetworksScreenState();
}

class _ExploreNetworksScreenState extends State<ExploreNetworksScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreNetworksProvider>().fetchNetworks();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _activeTabIndex = _tabController.index;
    });
    // Apply search immediately when switching tabs
    _applySearch(_searchController.text);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _applySearch(_searchController.text);
    });
  }

  void _applySearch(String query) {
    if (_activeTabIndex == 0) {
      context.read<ExploreNetworksProvider>().search(query);
    } else {
      context.read<ExploreUsersProvider>().search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Explorar',
          style: GoogleFonts.inter(
            fontSize: 18,
            letterSpacing: -0.04,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Redes'),
            Tab(text: 'Usuarios'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Compartida Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: _activeTabIndex == 0 ? 'Buscar redes...' : 'Buscar usuarios...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary.withValues(alpha: 0.7), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNetworksTab(),
                const _UserTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworksTab() {
    return Consumer<ExploreNetworksProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredNetworks.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (provider.status == ExploreNetworksStatus.error && provider.filteredNetworks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.errorMessage ?? 'Error desconocido',
                  style: GoogleFonts.inter(color: AppTheme.error, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.fetchNetworks(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (provider.filteredNetworks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: AppTheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron redes',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: provider.filteredNetworks.length,
          itemBuilder: (context, index) {
            final network = provider.filteredNetworks[index];
            return _NetworkCard(
              networkId: network.id,
              nombre: network.nombre,
              imageUrl: network.fotoPerfil,
              miembros: network.cantidadMiembros,
              acronym: network.acronym,
              onTap: () {
                context.push('/explore/networks/${network.id}');
              },
            );
          },
        );
      },
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final String networkId;
  final String nombre;
  final String? imageUrl;
  final int miembros;
  final String acronym;
  final VoidCallback onTap;

  const _NetworkCard({
    required this.networkId,
    required this.nombre,
    required this.imageUrl,
    required this.miembros,
    required this.acronym,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? SafeNetworkImage(url: imageUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        acronym,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  nombre,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1D3557),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'VER MÁS',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTab extends StatefulWidget {
  const _UserTab();

  @override
  State<_UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<_UserTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreUsersProvider>().fetchInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ExploreUsersProvider>().fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreUsersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredUsers.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (provider.status == ExploreUsersStatus.error && provider.filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.errorMessage ?? 'Error al cargar usuarios',
                  style: GoogleFonts.inter(color: AppTheme.error, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.fetchInitial(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (provider.filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: AppTheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron usuarios',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.filteredUsers.length + (provider.isFetching ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.filteredUsers.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  ),
                ),
              );
            }
            final user = provider.filteredUsers[index];
            return UserSearchTile(user: user);
          },
        );
      },
    );
  }
}
