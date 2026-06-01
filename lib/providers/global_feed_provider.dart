import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/feed_context.dart';
import '../services/api_service.dart';
import '../services/post_service.dart';
import 'post_store_provider.dart';

/// Responsabilidad principal:
/// Controlador de la vista "Explorar" (Global). Mantiene el estado de paginación para las pestañas de categorías ('noticias', 'marketplace', 'cursos').
///
/// Flujo dentro de la app:
/// Solicita páginas HTTP vía `PostService`, delega los objetos masivos al `PostStoreProvider` y retiene localmente solo una lista de IDs ordenados.
///
/// Dependencias críticas:
/// - `PostStoreProvider` (Caché global donde se inyectan los resultados).
/// - `PostService` (Red).
///
/// Side Effects:
/// - Tras un fetch exitoso, muta el `PostStoreProvider` indexando posts bajo `FeedContext.exploreGlobal` o `FeedContext.exploreTab`.
///
/// Recordatorios técnicos y CQRS:
/// - Deuda técnica de Estado: Este provider mantiene listas de IDs propias en memoria (en `CategoryState`), duplicando parcialmente los índices de `PostStoreProvider`. Debe evitarse mutar estas listas localmente sin sincronizar el Store.
class CategoryState {
  final List<String> postIds = [];
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
}

class GlobalFeedProvider extends ChangeNotifier {
  final PostService _postService;
  final PostStoreProvider _postStore;
  static const int _defaultLimit = 20;

  GlobalFeedProvider(this._postService, this._postStore);

  final Map<String, CategoryState> _states = {
    'noticias': CategoryState(),
    'marketplace': CategoryState(),
    'cursos': CategoryState(),
  };

  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  void setLoadedOnce() => _hasLoadedOnce = true;
  void resetLoadedOnce() => _hasLoadedOnce = false;

  void clear() {
    for (final state in _states.values) {
      state.postIds.clear();
      state.currentPage = 1;
      state.hasMore = true;
      state.errorMessage = null;
    }
    _hasLoadedOnce = false;
    notifyListeners();
  }

  String _selectedCategory = 'noticias';

  CategoryState get currentState => _states[_selectedCategory] ?? _states['noticias']!;

  CategoryState getCategoryState(String category) {
    return _states[category] ?? _states['noticias']!;
  }

  List<String> get postIds => List.unmodifiable(currentState.postIds);
  bool get isLoadingInitial => currentState.isLoadingInitial;
  bool get isLoadingMore => currentState.isLoadingMore;
  bool get hasMore => currentState.hasMore;
  int get currentPage => currentState.currentPage;
  String? get errorMessage => currentState.errorMessage;
  String get selectedCategory => _selectedCategory;

  Future<void> loadInitial({String category = 'noticias'}) async {
    _selectedCategory = category;
    final state = currentState;

    if (state.isLoadingInitial || state.isLoadingMore) {
      notifyListeners();
      return;
    }

    if (state.postIds.isNotEmpty) {
      // Ya tiene datos, no hacer fetch inicial de nuevo. Usar refreshFeed() si se desea recargar.
      notifyListeners();
      return;
    }

    state.isLoadingInitial = true;
    state.errorMessage = null;
    state.currentPage = 1;
    state.hasMore = true;
    notifyListeners();

    final result = await _loadFeedForCategory(
      category,
      page: state.currentPage,
      limit: _defaultLimit,
    );

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      final context = category.isEmpty 
          ? FeedContext.exploreGlobal() 
          : FeedContext.exploreTab(categoryId: category);
      _postStore.addBatchPosts(newPosts, context: context);
      
      state.postIds.clear();
      state.postIds.addAll(_removeDuplicatePosts(newPosts.map((p) => p.id).toList(), state));
      state.hasMore = newPosts.length >= _defaultLimit;
      _postStore.incrementFeedVersionGlobal();
    } else {
      state.errorMessage = result.message ?? 'Error al cargar el feed';
      state.postIds.clear();
      state.hasMore = false;
    }

    state.isLoadingInitial = false;
    notifyListeners();
  }

  Future<void> setCategory(String category) async {
    if (_selectedCategory == category) return;
    await loadInitial(category: category);
  }

  Future<void> refreshFeed() async {
    final state = currentState;
    state.postIds.clear(); // Forzar borrado para simular nueva carga
    await loadInitial(category: _selectedCategory);
  }

  Future<void> loadMore() async {
    final state = currentState;
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasMore) return;

    state.isLoadingMore = true;
    state.errorMessage = null;
    notifyListeners();

    final nextPage = state.currentPage + 1;
    final result = await _loadFeedForCategory(
      _selectedCategory,
      page: nextPage,
      limit: _defaultLimit,
    );

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      final context = _selectedCategory.isEmpty 
          ? FeedContext.exploreGlobal() 
          : FeedContext.exploreTab(categoryId: _selectedCategory);
      _postStore.addBatchPosts(newPosts, context: context);

      final filteredIds = _removeDuplicatePosts(newPosts.map((p) => p.id).toList(), state);
      if (filteredIds.isNotEmpty) {
        state.postIds.addAll(filteredIds);
      }
      if (newPosts.length < _defaultLimit) {
        state.hasMore = false;
      }
      if (newPosts.isNotEmpty) {
        state.currentPage = nextPage;
        _postStore.incrementFeedVersionGlobal();
      }
    } else {
      state.errorMessage =
          result.message ?? 'No se pudieron cargar más publicaciones';
    }

    state.isLoadingMore = false;
    notifyListeners();
  }

  Future<ApiResult<List<PostModel>>> _loadFeedForCategory(
    String category, {
    required int page,
    required int limit,
  }) async {
    final key = category.toLowerCase();
    if (key == 'noticias') {
      return _postService.fetchGlobalFeed(page: page, limit: limit);
    }
    if (key == 'marketplace') {
      return _postService.fetchArticlesFeed(
        page: page,
        limit: limit,
        categoria: 'venta',
      );
    }
    if (key == 'cursos') {
      return _postService.fetchArticlesFeed(
        page: page,
        limit: limit,
        categoria: 'cursos',
      );
    }
    return _postService.fetchGlobalFeed(page: page, limit: limit);
  }

  List<String> _removeDuplicatePosts(List<String> ids, CategoryState state) {
    final existingIds = state.postIds.toSet();
    return ids.where((id) => !existingIds.contains(id)).toList();
  }

  // ─── Mutadores Síncronos (Optimistic UI) ───────────────────────────────────

  /// Agrega un ID al inicio de la lista de una categoría.
  void prependPostId(String id, {String? category}) {
    final state = getCategoryState(category ?? _selectedCategory);
    if (!state.postIds.contains(id)) {
      state.postIds.insert(0, id);
      notifyListeners();
    }
  }

  /// Remueve un ID y retorna su índice original (útil para rollback).
  int removePostId(String id) {
    int removedIndex = -1;
    _states.forEach((cat, state) {
      final index = state.postIds.indexOf(id);
      if (index != -1) {
        state.postIds.removeAt(index);
        removedIndex = index;
      }
    });
    if (removedIndex != -1) notifyListeners();
    return removedIndex;
  }

  /// Inserta un ID en una posición específica (rollback).
  void insertPostId(int index, String id, {String? category}) {
    if (index < 0) return;
    final state = getCategoryState(category ?? _selectedCategory);
    if (!state.postIds.contains(id)) {
      final insertIndex = index.clamp(0, state.postIds.length);
      state.postIds.insert(insertIndex, id);
      notifyListeners();
    }
  }

  /// Reemplaza un ID por otro (cuando se confirma creación).
  void replacePostId(String oldId, String newId) {
    bool changed = false;
    _states.forEach((cat, state) {
      final index = state.postIds.indexOf(oldId);
      if (index != -1) {
        state.postIds[index] = newId;
        changed = true;
      }
    });
    if (changed) notifyListeners();
  }
}
