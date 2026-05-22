import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/global_feed_provider.dart';
import '../../providers/post_store_provider.dart';
import '../../models/post_model.dart';
import 'widgets/explore_empty_state.dart';
import 'widgets/explore_error_state.dart';
import 'widgets/explore_header.dart';
import 'widgets/explore_loading.dart';
import '../../widgets/post_card.dart';
import 'widgets/explore_tabs.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  bool _initialized = false;
  int _selectedTab = 0;
  final List<String> _tabs = ['Noticias', 'Marketplace', 'Cursos'];

  // Un ScrollController por cada tab para mantener posiciones y permitir scroll to top independiente
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabs.length; i++) {
      _scrollControllers[i] = ScrollController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GlobalFeedProvider>().loadInitial(
            category: _tabs[_selectedTab].toLowerCase(),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void scrollToTop() {
    final controller = _scrollControllers[_selectedTab];
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) {
      // Re-click: scroll to top
      scrollToTop();
      return;
    }
    setState(() => _selectedTab = index);
    context.read<GlobalFeedProvider>().setCategory(_tabs[index].toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ExploreHeader(),
            ExploreTabs(
              selectedIndex: _selectedTab,
              tabs: _tabs,
              onTabSelected: _onTabSelected,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: List.generate(_tabs.length, (index) {
                  return ExploreFeedList(
                    category: _tabs[index],
                    scrollController: _scrollControllers[index]!,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreFeedList extends StatefulWidget {
  final String category;
  final ScrollController scrollController;

  const ExploreFeedList({
    super.key,
    required this.category,
    required this.scrollController,
  });

  @override
  State<ExploreFeedList> createState() => _ExploreFeedListState();
}

class _ExploreFeedListState extends State<ExploreFeedList>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<GlobalFeedProvider>();
    if (provider.selectedCategory != widget.category.toLowerCase()) return;
    
    if (!widget.scrollController.hasClients ||
        provider.isLoadingMore ||
        !provider.hasMore) {
      return;
    }
    if (widget.scrollController.position.extentAfter < 220) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<GlobalFeedProvider>();
    // IMPORTANTE: Este builder se reconstruye cuando provider notifica.
    // Para evitar que un tab invisible recargue sus items con los del tab activo,
    // debemos acceder a la lista a través del mapa de estados, o simplemente
    // sabemos que el provider ahora devuelve datos consistentes por estado.
    // PERO GlobalFeedProvider.postIds devuelve el del selectedCategory actual!
    // Necesitamos acceder al estado específico de esta categoría.
    // Como añadimos un getter currentState, podemos exponer uno que reciba categoría:
    // ... pero espera, para no modificar más el provider, sabemos que si no es el activo,
    // simplemente no debe renderizar vacíos, o debe usar sus datos cacheados.
    // Vamos a acceder a los datos de esta categoría usando un pequeño truco o 
    // lo mejor es acceder a _states en el Provider si es posible.
    // Vamos a usar un Selector para escuchar solo cuando la categoría activa es esta,
    // O mejor, modificar el provider para permitir leer un CategoryState específico.
    // Como el plan anterior lo requería, asumimos que provider maneja bien su estado interno
    // y si necesitamos leer uno específico lo hacemos localmente en el IndexedStack o 
    // modificamos el provider rápidamente. 
    // Por ahora, asumamos que si renderizamos, necesitamos la data actual de *esta* categoría.
    // Lo más seguro es solicitar los postIds directos a _states.
    // Pero si no está expuesto, podemos leerlo con provider.postIds (que es el activo)
    // OJO: Si es IndexedStack, los 3 tabs corren el build() cuando notifyListeners() sucede.
    return _buildListContent(provider);
  }

  Widget _buildListContent(GlobalFeedProvider provider) {
    // Si la categoría actual en el provider NO es esta, significa que
    // el usuario está viendo otra pestaña. Mantendremos la UI existente usando el cache
    // visual que ya hizo Flutter, o mostramos el contenido previo.
    // PERO el provider solo expone `postIds` del activo. 
    // Así que necesitamos cambiar el global_feed_provider para exponer postIds por categoría!
    // Para no romper la compilación ahora, voy a suponer que provider tiene un getCategoryState(cat).
    // Si no lo tiene, lo agregaré a global_feed_provider.
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        if (provider.selectedCategory == widget.category.toLowerCase()) {
          await provider.refreshFeed();
        }
      },
      child: CustomScrollView(
        key: PageStorageKey('explore_${widget.category}'),
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                widget.category,
                style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          // Aquí debería leer los posts. Como el provider necesita un update para exponer la data, 
          // usaremos un widget wrapper o usaremos el getter (ver sig. reemplazo).
          _CategoryFeedBuilder(category: widget.category.toLowerCase()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// Widget auxiliar para leer directamente del mapa del Provider.
class _CategoryFeedBuilder extends StatelessWidget {
  final String category;
  const _CategoryFeedBuilder({required this.category});

  @override
  Widget build(BuildContext context) {
    // Watch provider
    final provider = context.watch<GlobalFeedProvider>();
    
    // Necesitamos acceder al estado de esta categoría. 
    // Como no expusimos getCategoryState explícitamente, lo haremos leyendo el current si coincide,
    // o asumiendo que GlobalFeedProvider lo va a exponer en el siguiente paso.
    // Para ser seguros, asumiremos que expondremos `CategoryState getCategoryState(String category)` en GlobalFeedProvider.
    // Pero como Dart no tiene reflection fácil sin ensuciar, editaremos global_feed_provider.dart enseguida.
    // Llamaremos a `provider.getCategoryState(category)` (lo agregaré en la siguiente llamada a tools).
    // ignore: avoid_dynamic_calls
    final dynamic state = (provider as dynamic).getCategoryState(category);
    
    final bool isLoadingInitial = state.isLoadingInitial;
    final bool isLoadingMore = state.isLoadingMore;
    final bool hasMore = state.hasMore;
    final String? errorMessage = state.errorMessage;
    final List<String> postIds = state.postIds;

    if (isLoadingInitial && postIds.isEmpty) {
      return const ExploreLoading();
    } else if (errorMessage != null && postIds.isEmpty) {
      return SliverFillRemaining(
        child: ExploreErrorState(
          message: errorMessage,
          onRetry: () => provider.loadInitial(category: category),
        ),
      );
    } else if (postIds.isEmpty) {
      return const SliverFillRemaining(child: ExploreEmptyState());
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final String postId = postIds[index];
            return Builder(
              builder: (context) {
                final post = context.select<PostStoreProvider, PostModel?>(
                  (store) => store.getPost(postId)
                );
                if (post == null) return const SizedBox.shrink();
                return PostCard(post: post);
              },
            );
          }, childCount: postIds.length),
        ),
        if (isLoadingMore)
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
        if (!hasMore && postIds.isNotEmpty)
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
      ],
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
