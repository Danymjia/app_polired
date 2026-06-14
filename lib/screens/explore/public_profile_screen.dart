import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/public_profile_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../services/read_model_cache_service.dart';
import '../../models/feed_context.dart';
import '../../repositories/conversations_repository.dart';
import '../../widgets/public_profile_header.dart';
import '../../widgets/public_profile_grid.dart';

/// Responsabilidad principal:
/// Perfil público de otros usuarios. Muestra su información general, opciones de contacto (Chat) y sus publicaciones.
///
/// Flujo dentro de la app:
/// Accesible al pulsar el avatar/nombre de un usuario en un post, comentario o búsqueda.
///
/// Dependencias críticas:
/// - `PublicProfileProvider` (Carga información y feed del usuario).
/// - `PostStoreProvider` (Renderiza publicaciones y artículos).
/// - `ConversationsRepository` (Inicia o recupera el chat 1-a-1).
/// - `ReadModelCacheService` (Limpia la caché del feed al salir).
///
/// Side Effects:
/// - Consulta el perfil y los posts del usuario especificado.
/// - Crea o recupera un chat en la base de datos al presionar el ícono de mensaje.
///
/// Recordatorios técnicos y CQRS:
/// - Usa `ReadModelCacheService.evict` en el `dispose()` usando un contexto guardado en `initState()`.
/// - Divide visualmente las publicaciones (texto/imágenes) de los artículos (venta/servicio).
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  // Saved in initState to avoid calling context.read() inside dispose().
  late ReadModelCacheService _cacheService;
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
    // Save reference now while context is still active.
    _cacheService = context.read<ReadModelCacheService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicProfileProvider>();
      provider.setCurrentUser(widget.userId);
      provider.fetchProfileInfo();
      provider.fetchInitialFeed();
    });
  }

  @override
  void dispose() {
    // Use the pre-saved reference — context.read() is unsafe in dispose().
    _cacheService.evict(FeedContext.profile(userId: widget.userId));
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
    return Consumer2<PublicProfileProvider, PostStoreProvider>(
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
              info != null ? '@${info.username}' : 'Perfil',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            centerTitle: true,
            actions: [
              _isLoadingChat
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.onSurface, size: 24),
                      onPressed: () async {
                        if (_isLoadingChat) return;
                        setState(() => _isLoadingChat = true);
                        final repo = context.read<ConversationsRepository>();
                        final result = await repo.getOrCreateConversation(widget.userId);
                        if (!mounted || !context.mounted) return;
                        setState(() => _isLoadingChat = false);
                        if (result.success && result.data != null) {
                          context.push(
                            '/chat/${result.data}',
                            extra: {
                              'contactId': widget.userId,
                              'contactName': info?.nombreCompleto ?? 'Usuario',
                              'contactAvatar': info?.fotoPerfil,
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message ?? 'Error al iniciar conversación')),
                          );
                        }
                      },
                    ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header del perfil ────────────────────────────────────
                if (info != null) PublicProfileHeader(profile: info),

                // ── Divider ──────────────────────────────────────────────
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

                // ── Grid del tab activo ──────────────────────────────────
                if (profileProvider.isLoadingFeed && allIds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (profileProvider.feedError != null && allIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
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
                    ),
                  )
                else
                  PublicProfileGrid(
                    postIds: _tabController.index == 0 ? publicationIds : articleIds,
                    isFetchingMore: profileProvider.isLoadingMoreFeed,
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}

