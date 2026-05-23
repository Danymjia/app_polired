import 'dart:math';
import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/post_service.dart';
import '../models/network_story_model.dart';
import '../models/feed_context.dart';
import 'post_store_provider.dart';

export '../models/feed_context.dart' show HomeFeedState;

/// Estado del provider en general.
enum FeedStatus { idle, loading, success, empty, error }

/// Proveedor de estado para las comunidades (redes) y el feed Home.
///
/// REGLAS ARQUITECTÓNICAS:
///   - Es el ÚNICO dueño del feed de Home.
///   - Mantiene un [HomeFeedState] por redId → cache multi-stream aislado.
///   - Todos los posts se resuelven vía [PostStoreProvider] (solo IDs aquí).
///   - NO contiene lógica de categorías globales.
///   - NO hace fallback a feeds mixtos.
class NetworkProvider extends ChangeNotifier {
  final NetworkService _networkService;
  final PostService _postService;
  final PostStoreProvider _postStore;

  static const int _defaultLimit = 20;

  NetworkProvider(this._networkService, this._postService, this._postStore) {
    loadStudentNetworks();
  }

  // ─── Redes del Estudiante ─────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _redes = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get redes => _redes;

  int? _redesCount;
  int? get redesCount => _redesCount;

  // ─── Home: Selección de red ───────────────────────────────────────────────
  NetworkStoryModel? _selectedNetwork;
  String? pendingAutoSelectNetworkId;

  FeedStatus _feedStatus = FeedStatus.idle;
  String? _feedError;
  List<NetworkStoryModel> _networkStories = [];

  NetworkStoryModel? get selectedNetwork => _selectedNetwork;
  FeedStatus get feedStatus => _feedStatus;
  bool get loadingPosts => _feedStatus == FeedStatus.loading;
  bool get emptyFeed => _feedStatus == FeedStatus.empty;
  String? get feedErrorState => _feedError;
  List<NetworkStoryModel> get networkStories => _networkStories;

  // ─── Cache multi-stream por redId ─────────────────────────────────────────
  /// Cada redId tiene su propio [HomeFeedState] completamente aislado.
  final Map<String, HomeFeedState> _feedByNetwork = {};

  /// Estado del feed de la red actualmente seleccionada.
  HomeFeedState get _activeFeed =>
      _feedByNetwork.putIfAbsent(_selectedNetwork?.id ?? '', HomeFeedState.new);

  /// IDs del feed de la red activa (resueltos vía PostStore).
  List<String> get homePostIds =>
      List.unmodifiable(_activeFeed.postIds);

  bool get isLoadingInitialFeed => _activeFeed.isLoadingInitial;
  bool get isLoadingMoreFeed => _activeFeed.isLoadingMore;
  bool get hasMoreFeed => _activeFeed.hasMore;
  String? get homeFeedError => _activeFeed.errorMessage;

  // ─── Cargar redes del estudiante para el Home ─────────────────────────────
  Future<void> loadStudentNetworks() async {
    _isLoading = true;
    notifyListeners();

    final joinedResult = await _networkService.getRedesEstudianteStories();
    final availableResult = await _networkService.getAvailableNetworksStories();

    List<NetworkStoryModel> joined = [];
    if (joinedResult.success && joinedResult.data != null) {
      joined = joinedResult.data!;
    }

    List<NetworkStoryModel> available = [];
    if (availableResult.success && availableResult.data != null) {
      final joinedIds = joined.map((e) => e.id).toSet();
      available = availableResult.data!.where((e) => !joinedIds.contains(e.id)).toList();
    }

    _networkStories = [...joined, ...available];

    if (joined.isEmpty) {
      _feedStatus = FeedStatus.empty;
    } else {
      if (pendingAutoSelectNetworkId != null) {
        final target = joined.cast<NetworkStoryModel?>().firstWhere(
            (n) => n?.id == pendingAutoSelectNetworkId, orElse: () => null);
        pendingAutoSelectNetworkId = null;
        if (target != null) {
          await selectNetwork(target);
        }
      } else if (_selectedNetwork == null) {
        final randomIndex = Random().nextInt(joined.length);
        await selectNetwork(joined[randomIndex]);
      }
      // Si ya hay red seleccionada, conservar el estado actual.
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Seleccionar red y cargar su feed ────────────────────────────────────
  /// Cambia la red activa y carga su feed si no está en cache.
  Future<void> selectNetwork(NetworkStoryModel network) async {
    if (_selectedNetwork?.id == network.id && _feedStatus == FeedStatus.success) {
      return;
    }

    _selectedNetwork = network;
    _feedStatus = FeedStatus.loading;
    _feedError = null;
    notifyListeners();

    final state = _feedByNetwork.putIfAbsent(network.id, HomeFeedState.new);

    // Si ya tiene datos en cache, usar directamente
    if (state.postIds.isNotEmpty) {
      _feedStatus = FeedStatus.success;
      notifyListeners();
      return;
    }

    await _loadInitialForNetwork(network.id, state);
  }

  /// Cambia la red activa usando solo su ID (útil para navegación profunda)
  Future<void> selectNetworkById(String id) async {
    final network = _networkStories.cast<NetworkStoryModel?>().firstWhere(
        (n) => n?.id == id, orElse: () => null);
    if (network != null) {
      await selectNetwork(network);
    }
  }

  /// Carga la primera página del feed de una red específica.
  Future<void> _loadInitialForNetwork(String redId, HomeFeedState state) async {
    if (state.isLoadingInitial || state.isLoadingMore) return;

    state.isLoadingInitial = true;
    state.errorMessage = null;
    state.currentPage = 1;
    state.hasMore = true;
    notifyListeners();

    final result = await _postService.fetchFeedByNetwork(
      redId,
      page: 1,
      limit: _defaultLimit,
    );

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _postStore.addBatchPosts(newPosts, context: FeedContext.home(communityId: redId));
      state.postIds.clear();
      state.postIds.addAll(_deduplicateIds(newPosts.map((p) => p.id).toList(), state));
      state.hasMore = newPosts.length >= _defaultLimit;
      _feedStatus = state.postIds.isEmpty ? FeedStatus.empty : FeedStatus.success;
      _postStore.incrementFeedVersionNetwork(redId);
    } else {
      state.errorMessage = result.message ?? 'Error al cargar el feed';
      _feedStatus = FeedStatus.error;
      _feedError = state.errorMessage;
    }

    state.isLoadingInitial = false;
    notifyListeners();
  }

  // ─── Paginación: cargar más posts ─────────────────────────────────────────
  /// Carga la siguiente página del feed de la red activa.
  Future<void> loadMoreForNetwork() async {
    final redId = _selectedNetwork?.id;
    if (redId == null) return;

    final state = _feedByNetwork.putIfAbsent(redId, HomeFeedState.new);
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasMore) return;

    state.isLoadingMore = true;
    notifyListeners();

    final nextPage = state.currentPage + 1;
    final result = await _postService.fetchFeedByNetwork(
      redId,
      page: nextPage,
      limit: _defaultLimit,
    );

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _postStore.addBatchPosts(newPosts, context: FeedContext.home(communityId: redId));

      final filteredIds = _deduplicateIds(newPosts.map((p) => p.id).toList(), state);
      if (filteredIds.isNotEmpty) {
        state.postIds.addAll(filteredIds);
      }
      if (newPosts.length < _defaultLimit) {
        state.hasMore = false;
      }
      if (newPosts.isNotEmpty) {
        state.currentPage = nextPage;
        _postStore.incrementFeedVersionNetwork(redId);
      }
    } else {
      state.errorMessage = result.message ?? 'No se pudieron cargar más publicaciones';
    }

    state.isLoadingMore = false;
    notifyListeners();
  }

  // ─── Refresh del feed activo ──────────────────────────────────────────────
  Future<void> refreshHomeFeed() async {
    final redId = _selectedNetwork?.id;
    if (redId == null) {
      await loadStudentNetworks();
      return;
    }

    // Limpiar cache de la red activa para forzar recarga
    final state = _feedByNetwork.putIfAbsent(redId, HomeFeedState.new);
    state.postIds.clear();
    state.currentPage = 1;
    state.hasMore = true;
    state.errorMessage = null;

    _feedStatus = FeedStatus.loading;
    notifyListeners();

    await _loadInitialForNetwork(redId, state);
  }

  // ─── Operaciones de redes (onboarding) ────────────────────────────────────
  Future<void> fetchRedesDelEstudiante() async {
    final result = await _networkService.getRedesDelEstudiante();
    if (result.success && result.data != null) {
      _redes = result.data!;
      _redesCount = _redes.length;
      notifyListeners();
    }
  }

  Future<void> fetchRedes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.getRedes();

    if (result.success && result.data != null) {
      _redes = result.data!;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> unirseRedes(List<String> redesIds) async {
    final ids = redesIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      _errorMessage = 'No hay redes válidas para unirse';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (String id in ids) {
        final result = await _networkService.unirseRed(id);
        if (!result.success) {
          if (result.message != null && result.message!.contains('Ya perteneces')) {
            continue;
          }
          _errorMessage = result.message;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      await loadStudentNetworks();
      await fetchRedesDelEstudiante();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Abandonar una red ────────────────────────────────────────────────────
  Future<bool> abandonarRed(String redId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.salirseRed(redId);
    if (result.success) {
      // Limpiar cache de la red abandonada
      _feedByNetwork.remove(redId);
      if (_selectedNetwork?.id == redId) {
        _selectedNetwork = null;
        _feedStatus = FeedStatus.idle;
      }
      await loadStudentNetworks();
      await fetchRedesDelEstudiante();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Optimistic UI — Mutadores Síncronos ──────────────────────────────────
  /// Requiere [FeedContext.home]. Inserta al inicio del feed de la red activa.
  void prependPostId(String id) {
    final redId = _selectedNetwork?.id ?? '';
    final state = _feedByNetwork.putIfAbsent(redId, HomeFeedState.new);
    if (!state.postIds.contains(id)) {
      state.postIds.insert(0, id);
      notifyListeners();
    }
  }

  /// Remueve un ID de TODOS los streams de redes (para eliminación).
  /// Retorna el índice original en la red activa (-1 si no encontrado).
  int removePostId(String id) {
    int removedIndex = -1;
    _feedByNetwork.forEach((redId, state) {
      final index = state.postIds.indexOf(id);
      if (index != -1) {
        state.postIds.removeAt(index);
        if (redId == _selectedNetwork?.id) removedIndex = index;
      }
    });
    if (removedIndex != -1) notifyListeners();
    return removedIndex;
  }

  /// Inserta en posición específica (rollback de delete).
  void insertPostId(int index, String id) {
    if (index < 0) return;
    final redId = _selectedNetwork?.id ?? '';
    final state = _feedByNetwork.putIfAbsent(redId, HomeFeedState.new);
    if (!state.postIds.contains(id)) {
      final insertIndex = index.clamp(0, state.postIds.length);
      state.postIds.insert(insertIndex, id);
      notifyListeners();
    }
  }

  /// Reemplaza tempId por el ID real (confirmación de optimistic create).
  void replacePostId(String oldId, String newId) {
    bool changed = false;
    _feedByNetwork.forEach((_, state) {
      final index = state.postIds.indexOf(oldId);
      if (index != -1) {
        state.postIds[index] = newId;
        changed = true;
      }
    });
    if (changed) notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<String> _deduplicateIds(List<String> ids, HomeFeedState state) {
    final existing = state.postIds.toSet();
    return ids.where((id) => !existing.contains(id)).toList();
  }
}
