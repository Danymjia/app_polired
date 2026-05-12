import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/network_provider.dart';
import '../../widgets/network_avatar.dart';
import '../../widgets/post_card.dart';
import '../post/add_post_screen.dart';

/// Pantalla de Feed Principal.
/// Muestra las historias de las redes y las publicaciones correspondientes
/// a la red seleccionada en el [NetworkProvider].
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
              backgroundColor: AppTheme.surface.withValues(alpha: 0.8),
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
                  ),
                  onPressed: () {
                    // TODO: Implementar la pantalla del feed de Notificaciones del usuario
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
          ),
          
          // Network Stories Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: networkProvider.networkStories.map((network) {
                    final isSelected = networkProvider.selectedNetwork?.id == network.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: NetworkAvatar(
                        network: network,
                        isSelected: isSelected,
                        onTap: () {
                          if (network.isJoined) {
                            networkProvider.selectNetwork(network);
                          } else {
                            // Navigate to Network Profile (dummy)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ir al perfil de ${network.acronym}'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Main Feed
          if (networkProvider.loadingPosts)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (networkProvider.emptyFeed)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay publicaciones',
                      style: AppTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Únete a esta red para ver su contenido.',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = networkProvider.postsByNetwork[index];
                  // If last item, add bottom padding for BottomNavBar
                  if (index == networkProvider.postsByNetwork.length - 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: PostCard(post: post),
                    );
                  }
                  return PostCard(post: post);
                },
                childCount: networkProvider.postsByNetwork.length,
              ),
            ),
        ],
      ),
    );
  }
}
