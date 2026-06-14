import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/network_provider.dart';
import '../../../providers/network_profile_provider.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_store_provider.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/network_options_bottom_sheet.dart';
import '../../../widgets/network_badge.dart';
import '../../../widgets/fullscreen_image_viewer.dart';
import 'widgets/restricted_feed_overlay.dart';

/// Responsabilidad principal:
/// Muestra los detalles de una red comunitaria (estadísticas, descripción) y su feed exclusivo.
///
/// Flujo dentro de la app:
/// Accesible desde los resultados de búsqueda de redes o desde el carrusel superior del Home.
///
/// Dependencias críticas:
/// - `NetworkProfileProvider` (para cargar el perfil y manejar la paginación del feed).
/// - `NetworkProvider` (para unirse a la red y comprobar si el usuario es miembro).
/// - `PostStoreProvider` (para renderizar los posts en la UI).
///
/// Side Effects:
/// - Consulta el backend para cargar información de la red y su feed de publicaciones.
/// - Si el usuario no es miembro, el feed se corta en el quinto elemento mostrando `RestrictedFeedOverlay`.
///
/// Recordatorios técnicos y CQRS:
/// - La lógica de membresía (`isMember`) verifica activamente la colección de `networkStories`.
class NetworkProfileScreen extends StatefulWidget {
  final String networkId;

  const NetworkProfileScreen({super.key, required this.networkId});

  @override
  State<NetworkProfileScreen> createState() => _NetworkProfileScreenState();
}

class _NetworkProfileScreenState extends State<NetworkProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final netProvider = context.read<NetworkProvider>();
    // Must check isJoined: true — networkStories may also contain available (unjoined) networks
    final isMember = netProvider.networkStories.any((n) => n.id == widget.networkId && n.isJoined);
    context.read<NetworkProfileProvider>().loadProfile(widget.networkId, isMember: isMember);
  }

  void _onUnirsePressed() async {
    final netProvider = context.read<NetworkProvider>();
    final success = await netProvider.unirseRedes([widget.networkId]);
    if (success && mounted) {
      await netProvider.loadStudentNetworks();
      _loadData(); // reload profile as member
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(netProvider.errorMessage ?? 'Error al unirse a la red')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer2<NetworkProvider, NetworkProfileProvider>(
        builder: (context, netProvider, profileProvider, child) {
          // Must check isJoined: true — networkStories may also contain available (unjoined) networks
          final isMember = netProvider.networkStories.any((n) => n.id == widget.networkId && n.isJoined);
          
          if (profileProvider.status == NetworkProfileStatus.loading && profileProvider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.status == NetworkProfileStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(profileProvider.errorMessage ?? 'Error al cargar el perfil'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final profile = profileProvider.profile;
          if (profile == null) {
            return const Center(child: Text('Perfil no encontrado'));
          }

          return CustomScrollView(
            // Pagination logic
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top AppBar
              SliverAppBar(
                backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
                pinned: true,
                elevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'Polired',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppTheme.onSurface),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => NetworkOptionsBottomSheet(
                          networkId: widget.networkId,
                          networkName: profile.nombre,
                          isMember: isMember,
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // Profile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (profile.fotoPerfil != null && profile.fotoPerfil!.isNotEmpty) {
                                    FullscreenImageViewer.show(context, [profile.fotoPerfil!], isCircular: true);
                                  }
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.surfaceContainerHighest,
                                    border: Border.all(color: AppTheme.outlineVariant),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: profile.fotoPerfil != null && profile.fotoPerfil!.isNotEmpty
                                      ? SafeNetworkImage(url: profile.fotoPerfil!, fit: BoxFit.cover)
                                      : const Icon(Icons.groups, size: 40, color: AppTheme.onSurfaceVariant),
                                ),
                              ),
                              if (profile.esVerificada || profile.esOficial)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: NetworkBadge(
                                    esVerificada: profile.esVerificada,
                                    esOficial: profile.esOficial,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    profile.nombre,
                                    style: AppTheme.headlineMedium.copyWith(
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildStat(profile.cantidadMiembros.toString(), 'miembros'),
                                    const SizedBox(width: 16),
                                    _buildStat(profile.publicacionesCount.toString(), 'publicaciones'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (profile.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ExpandableDescription(text: profile.descripcion),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: isMember
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.outlineVariant),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                ),
                                child: Text(
                                  'Miembro',
                                  style: AppTheme.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              )
                            : PrimaryButton(
                                onPressed: _onUnirsePressed,
                                isLoading: netProvider.isLoading,
                                label: 'Unirse',
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Espaciador entre header y posts
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Posts List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Check if we need to load more (only if member)
                    if (isMember && index == profileProvider.postIds.length - 1 && profileProvider.hasMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        profileProvider.loadMore(widget.networkId, isMember: isMember);
                      });
                    }

                    // Handling non-member restrictions
                    if (!isMember) {
                      if (index > 4) {
                        return const SizedBox.shrink(); // Hide anything beyond 5
                      }
                      
                      final postId = profileProvider.postIds[index];
                      return Builder(
                        builder: (context) {
                          final post = context.select<PostStoreProvider, PostModel?>(
                            (store) => store.getPost(postId)
                          );
                          if (post == null) return const SizedBox.shrink();

                          if (index == 4 || index == profileProvider.postIds.length - 1) {
                            return RestrictedFeedOverlay(
                              onJoinPressed: netProvider.isLoading ? () {} : _onUnirsePressed,
                              child: IgnorePointer(
                                child: SizedBox(
                                  height: 350, // Fix height to look cut off
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: OverflowBox(
                                        maxHeight: double.infinity,
                                        alignment: Alignment.topCenter,
                                          child: PostCard(
                                            post: post,
                                            enableNetworkNavigation: false,
                                          ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          return IgnorePointer(child: PostCard(
                            post: post,
                            enableNetworkNavigation: false,
                          ));
                        },
                      );
                    }

                    // Member sees full post Normally
                    if (index == profileProvider.postIds.length) {
                      return profileProvider.isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                    
                    final postId = profileProvider.postIds[index];
                    return Builder(
                      builder: (context) {
                        final post = context.select<PostStoreProvider, PostModel?>(
                          (store) => store.getPost(postId)
                        );
                        if (post == null) return const SizedBox.shrink();
                        return PostCard(
                          post: post,
                          enableNetworkNavigation: false,
                        );
                      },
                    );
                  },
                  childCount: isMember 
                      ? profileProvider.postIds.length + (profileProvider.hasMore ? 1 : 0)
                      : (profileProvider.postIds.length > 5 ? 5 : profileProvider.postIds.length),
                ),
              ),
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 0.5,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;
  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (!_expanded && widget.text.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ver más',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

