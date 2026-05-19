import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/post_service.dart';
import '../models/network_story_model.dart';
import '../models/post_model.dart';
import 'post_store_provider.dart';

/// Estado del feed.
enum FeedStatus { idle, loading, success, empty, error }

/// Proveedor de estado para las comunidades (redes) y el feed de publicaciones.
/// Gestiona la selección de redes, la carga real de posts desde el backend
/// y la suscripción a comunidades.
class NetworkProvider extends ChangeNotifier {
  final NetworkService _networkService;
  final PostService _postService;
  final PostStoreProvider _postStore;

  NetworkProvider(this._networkService, this._postService, this._postStore) {
    // Cargar redes y feed al iniciar
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

  Future<void> fetchRedesDelEstudiante() async {
    final result = await _networkService.getRedesDelEstudiante();
    if (result.success && result.data != null) {
      _redesCount = result.data;
      notifyListeners();
    }
  }

  // ─── Home Feed State ───────────────────────────────────────────────────────
  NetworkStoryModel? _selectedNetwork;
  FeedStatus _feedStatus = FeedStatus.idle;
  String? _feedError;
  List<PostModel> _posts = [];
  List<NetworkStoryModel> _networkStories = [];

  NetworkStoryModel? get selectedNetwork => _selectedNetwork;
  FeedStatus get feedStatus => _feedStatus;
  bool get loadingPosts => _feedStatus == FeedStatus.loading;
  bool get emptyFeed => _feedStatus == FeedStatus.empty;
  String? get feedErrorState => _feedError;
  List<PostModel> get postsByNetwork => _posts;
  List<NetworkStoryModel> get networkStories => _networkStories;

  // ─── Cargar redes del estudiante para el Home ─────────────────────────────
  /// Carga las redes del estudiante desde GET /estudiantes/listar/redes.
  /// Si el estudiante no pertenece a ninguna red, el feed queda vacío (no hay fallback global).
  Future<void> loadStudentNetworks() async {
    _isLoading = true;
    notifyListeners();

    final result = await _networkService.getRedesEstudianteStories();

    if (result.success && result.data != null && result.data!.isNotEmpty) {
      _networkStories = result.data!;
      // Seleccionar la primera red automáticamente y cargar su feed
      await selectNetwork(_networkStories.first);
    } else {
      // Sin redes unidas: mostrar redes disponibles en el carrusel.
      _feedStatus = FeedStatus.empty;
      _posts = [];
      
      final availableResult = await _networkService.getAvailableNetworksStories();
      if (availableResult.success && availableResult.data != null) {
        _networkStories = availableResult.data!;
      } else {
        _networkStories = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Seleccionar red y cargar su feed ────────────────────────────────────
  /// Carga publicaciones de una red específica via GET /publicaciones/red/:redId.
  /// NO hace fallback al feed global. Si falla, muestra estado de error.
  Future<void> selectNetwork(NetworkStoryModel network) async {
    if (_selectedNetwork?.id == network.id && _feedStatus == FeedStatus.success) return;

    _selectedNetwork = network;
    _feedStatus = FeedStatus.loading;
    _feedError = null;
    notifyListeners();

    final result = await _postService.fetchFeedByNetwork(network.id);
    if (result.success && result.data != null) {
      _posts = result.data!;
      // Registrar en el store global para sincronización de likes/saves
      _postStore.addPosts(_posts);
      _feedStatus = _posts.isEmpty ? FeedStatus.empty : FeedStatus.success;
    } else {
      _feedStatus = FeedStatus.error;
      _feedError = result.message ?? 'No se pudieron cargar las publicaciones';
      _posts = [];
    }

    notifyListeners();
  }

  // ─── Refresh del feed actual ──────────────────────────────────────────────
  Future<void> refreshFeed() async {
    if (_selectedNetwork != null) {
      _feedStatus = FeedStatus.loading;
      notifyListeners();
      await selectNetwork(_selectedNetwork!);
    } else {
      await loadStudentNetworks();
    }
  }

  // ─── Operaciones de redes (onboarding) ────────────────────────────────────
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
}
