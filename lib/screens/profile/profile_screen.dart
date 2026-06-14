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
import '../../widgets/fullscreen_image_viewer.dart';
import '../../services/socket_service.dart';

/// Responsabilidad principal:
/// Pantalla principal del Perfil de Usuario ("Mi Perfil"). Muestra estadísticas (número de redes, posts), biografía, y un feed personal dividido entre Publicaciones y Artículos.
///
/// Flujo dentro de la app:
/// Inicia peticiones asíncronas para refrescar las estadísticas del usuario. Delega el renderizado de la cuadrícula inferior a `PublicProfileGrid`, pasándole sublistas de IDs filtrados.
///
/// Dependencias críticas:
/// - `MyProfileFeedProvider` (Gestión paginada de los IDs de los posts del usuario activo).
/// - `PostStoreProvider` (Entity Cache para resolver esos IDs e identificar cuáles son Artículos `isArticle`).
///
/// Side Effects:
/// - Reconstrucciones manuales del TabBar: Utiliza un `addListener(() => setState(() {}))` en el `_tabController` para forzar la reevaluación de las listas filtradas en tiempo real.
///
/// Recordatorios técnicos y CQRS:
/// - Filtrado Eficiente: La separación entre Artículos y Publicaciones es muy rápida porque solo se filtran listas de `String` (IDs) en memoria mediante el caché `PostStoreProvider`, sin hacer llamadas REST extra al servidor.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _strikesChipVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // ← AGREGAR ESTA LÍNEA
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkProvider>().fetchRedesDelEstudiante();
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<MyProfileFeedProvider>().fetchInitialFeed(user.id);
      }
    });

    final socketService = context.read<SocketService>();
    socketService.on('nuevo_strike', _handleNuevoStrike);
  }

  void _handleNuevoStrike(dynamic data) {
    if (mounted) {
      context.read<AuthProvider>().syncProfileFromServer();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      try {
        context.read<SocketService>().off('nuevo_strike', _handleNuevoStrike);
      } catch (_) {}
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      context.read<MyProfileFeedProvider>().fetchMoreFeed(user.id);
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
    return GestureDetector(
      onTap: () {
        if (url != null && url.isNotEmpty) {
          FullscreenImageViewer.show(context, [url], isCircular: true);
        }
      },
      child: Container(
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
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.add, color: AppTheme.primaryText, size: 26),
          tooltip: 'Nueva publicación',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostScreen()),
          ),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            final authProv = context.read<AuthProvider>();
            final myFeed = context.read<MyProfileFeedProvider>();
            final netProv = context.read<NetworkProvider>();
            await authProv.syncProfileFromServer();
            await myFeed.fetchInitialFeed(user.id);
            await netProv.fetchRedesDelEstudiante();
          }
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null && user.strikes.isNotEmpty && _strikesChipVisible && !user.suspendido)
                GestureDetector(
                  onTap: () => context.push('/configuracion/strikes'),
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade600, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tienes ${user.strikes.length} de 5 advertencias',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.primaryText, size: 22),
                          onPressed: () {
                            setState(() {
                              _strikesChipVisible = false;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              // ── Header: Avatar + Stats + Bio + Botones ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                children: [
                                  _buildStat(
                                    (user?.publicacionesCount != null && user!.publicacionesCount > 0)
                                        ? user.publicacionesCount.toString()
                                        : (allIds.isNotEmpty ? allIds.length.toString() : '0'),
                                    'Publicaciones',
                                  ),
                                  const SizedBox(width: 28),
                                  GestureDetector(
                                    onTap: () {
                                      if (redesList.isNotEmpty) {
                                        _showNetworksModal(context, redesList);
                                      }
                                    },
                                    child: _buildStat(
                                      redesCount?.toString() ?? '0',
                                      'Redes',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user != null && user.suspendido && _strikesChipVisible) ...[
                      GestureDetector(
                        onTap: () => context.push('/configuracion/strikes'),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.block_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu cuenta ha sido suspendida',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _strikesChipVisible = false;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ),
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
                                onPressed: () {},
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
                                  'Mi Red',
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

              // ── Divider ─────────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
              ),

              // ── TabBar ────────────────────────────────────────
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 20), text: 'Publicaciones'),
                  Tab(icon: Icon(Icons.shopping_bag_rounded, size: 20), text: 'Artículos'),
                ],
              ),

              // ── Contenido del tab activo (loading / error / grid) ────
              if (myProfileFeedProvider.isLoadingFeed && allIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (myProfileFeedProvider.feedError != null && allIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
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
                  ),
                )
              else
                PublicProfileGrid(
                  postIds: _tabController.index == 0 ? publicationIds : articleIds,
                  isFetchingMore: myProfileFeedProvider.isLoadingMoreFeed,
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
  // ── Modal de Redes Unidas ────────────────────────────────────────────────
  void _showNetworksModal(BuildContext context, List<dynamic> initialRedes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.5,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              // Modal Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 0),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.surfaceContainer,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Redes a las que perteneces',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<NetworkProvider>(
                  builder: (context, networkProvider, child) {
                    final redesList = networkProvider.redes;
                    if (redesList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.group_outlined, size: 48, color: AppTheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no hay redes',
                              style: GoogleFonts.inter(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: redesList.length,
                      itemBuilder: (context, index) {
                        final net = redesList[index];
                        final netId = net['_id'] ?? '';
                        final netNombre = net['nombre'] ?? 'Red';
                        final netDesc = net['descripcion'] ?? '';
                        final netFoto = net['fotoPerfil'];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(modalContext);
                              if (netId.isNotEmpty) {
                                context.push('/explore/networks/$netId');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  CircularNetworkAvatar(
                                    imageUrl: netFoto,
                                    initials: netNombre.isNotEmpty ? netNombre[0].toUpperCase() : 'R',
                                    size: 48,
                                    backgroundColor: AppTheme.surfaceContainerLow,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          netNombre,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: -0.5,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        if (netDesc.isNotEmpty)
                                          Text(
                                            netDesc,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


