import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/explore_networks_provider.dart';
import '../../../widgets/safe_network_image.dart';

class ExploreNetworksScreen extends StatefulWidget {
  const ExploreNetworksScreen({super.key});

  @override
  State<ExploreNetworksScreen> createState() => _ExploreNetworksScreenState();
}

class _ExploreNetworksScreenState extends State<ExploreNetworksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreNetworksProvider>().fetchNetworks();
    });
    
    _searchController.addListener(() {
      context.read<ExploreNetworksProvider>().search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Explorar redes',
          style: AppTheme.displayMedium.copyWith(
            fontSize: 18,
            letterSpacing: -0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ExploreNetworksProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingM),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Buscar redes...',
                      hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.outline),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.outline, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(ExploreNetworksProvider provider) {
    if (provider.isLoading && provider.filteredNetworks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ExploreNetworksStatus.error) {
      return Center(
        child: Text(
          provider.errorMessage ?? 'Error desconocido',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
        ),
      );
    }

    if (provider.filteredNetworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.outlineVariant),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'No se encontraron redes',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTheme.spacingM,
        crossAxisSpacing: AppTheme.spacingM,
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
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Image
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? SafeNetworkImage(url: imageUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        acronym,
                        style: AppTheme.headlineMedium.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
            ),
            
            // Name
            Text(
              nombre,
              style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Button
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
                style: AppTheme.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
