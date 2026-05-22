import 'dart:math';
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
      _redes = result.data!;
      _redesCount = _redes.length;
      notifyListeners();
    }
  }

  // ─── Home Feed State ───────────────────────────────────────────────────────
  NetworkStoryModel? _selectedNetwork;
  String? pendingAutoSelectNetworkId;

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
  /// Carga las redes del estudiante y las sugerencias combinadas.
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

    // Mantener las unidas primero, luego las sugerencias
    _networkStories = [...joined, ...available];

    if (joined.isEmpty) {
      _feedStatus = FeedStatus.empty;
      _posts = [];
    } else {
      // Manejar auto-selección si existe una red pendiente de seleccionar tras unirse
      if (pendingAutoSelectNetworkId != null) {
        final target = joined.cast<NetworkStoryModel?>().firstWhere(
            (n) => n?.id == pendingAutoSelectNetworkId, orElse: () => null);
        
        pendingAutoSelectNetworkId = null; // Consumir evento
        if (target != null) {
          await selectNetwork(target);
        }
      } 
      // Seleccionar random inicial si no hay red seleccionada activa
      else if (_selectedNetwork == null) {
        final randomIndex = Random().nextInt(joined.length);
        final randomNetwork = joined[randomIndex];
        await selectNetwork(randomNetwork);
      }
      // Si _selectedNetwork != null, respetamos la selección actual y no la sobreescribimos.
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
      _postStore.mergePosts(_posts);
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

  // ─── Abandonar una red ────────────────────────────────────────────────────
  Future<bool> abandonarRed(String redId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.salirseRed(redId);
    if (result.success) {
      await loadStudentNetworks();
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
}
