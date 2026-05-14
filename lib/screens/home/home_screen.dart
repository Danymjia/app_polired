import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/network_provider.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/post_card.dart';
import '../notifications/notifications_screen.dart';
import '../post/add_post_screen.dart';

/// Pantalla de Feed Principal.
/// Consume publicaciones reales desde el backend vía [NetworkProvider].
/// Soporta: loading, empty, error y pull-to-refresh.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();

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
        onRefresh: () => networkProvider.refreshFeed(),
        child: CustomScrollView(
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
            if (networkProvider.isLoading && networkProvider.networkStories.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (networkProvider.loadingPosts)
              const SliverFillRemaining(
                child: Center(child: _FeedLoadingIndicator()),
              )
            else if (networkProvider.feedStatus == FeedStatus.error)
              SliverFillRemaining(
                child: _ErrorState(
                  message: networkProvider.feedErrorState ?? 'Error al cargar publicaciones',
                  onRetry: () => networkProvider.refreshFeed(),
                ),
              )
            else if (networkProvider.emptyFeed)
              SliverFillRemaining(
                child: _EmptyFeedState(
                  hasNetworks: networkProvider.networkStories.isNotEmpty,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = networkProvider.postsByNetwork[index];
                    final isLast = index == networkProvider.postsByNetwork.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 80.0 : 0),
                      child: PostCard(post: post),
                    );
                  },
                  childCount: networkProvider.postsByNetwork.length,
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
                      onTap: () => provider.selectNetwork(network),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

// ─── Loading skeleton del feed ─────────────────────────────────────────────────
class _FeedLoadingIndicator extends StatelessWidget {
  const _FeedLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primary),
        const SizedBox(height: 16),
        Text(
          'Cargando publicaciones...',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EmptyFeedState extends StatelessWidget {
  final bool hasNetworks;
  const _EmptyFeedState({required this.hasNetworks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNetworks ? Icons.article_outlined : Icons.people_outline,
              size: 72,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              hasNetworks ? 'Sin publicaciones aún' : 'Únete a una red',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasNetworks
                  ? 'Sé el primero en publicar en esta red.'
                  : 'Únete a redes comunitarias para ver su contenido.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
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
