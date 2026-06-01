import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';
import '../models/post_model.dart';
import '../services/public_profile_service.dart';
import 'post_store_provider.dart';

/// Responsabilidad principal:
/// Estado para el Perfil Público de OTRO estudiante, manejando un caché LRU (Least Recently Used) simplificado para navegación rápida sin re-fetching constante.
///
/// Flujo dentro de la app:
/// Usado en la pantalla de Perfil Público. Carga info y feed y vuelca los posts al `PostStoreProvider`.
///
/// Dependencias críticas:
/// - `PublicProfileService` (HTTP).
/// - `PostStoreProvider` (Caché global).
///
/// Side Effects:
/// - Almacena instancias masivas de perfiles en `_profileCache`.
/// - Inyecta posts en el Store central.
///
/// Recordatorios técnicos y CQRS:
/// - Fuga de memoria (Memory Leak Alert): El diccionario `_profileCache` crece indefinidamente al visitar usuarios sin mecanismo de expiración ni límite de tamaño. Deuda técnica que impacta en sesiones largas.
class PublicProfileCache {
  final PublicProfileModel info;
  final List<String> postIds;
  final DateTime timestamp;

  PublicProfileCache({
    required this.info,
    required this.postIds,
    required this.timestamp,
  });
}

class PublicProfileProvider extends ChangeNotifier {
  final PublicProfileService _publicProfileService;
  final PostStoreProvider _postStore;

  PublicProfileProvider(this._publicProfileService, this._postStore);

  // States
  bool _isLoadingInfo = false;
  bool _isLoadingFeed = false;
  bool _isLoadingMoreFeed = false;
  String? _infoError;
  String? _feedError;

  // Cache
  final Map<String, PublicProfileCache> _profileCache = {};

  // Current Profile
  String? _currentUserId;
  PublicProfileModel? _currentInfo;
  List<String> _currentPostIds = [];
  int _currentFeedPage = 1;
  bool _hasMoreFeed = true;

  bool get isLoadingInfo => _isLoadingInfo;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  String? get infoError => _infoError;
  String? get feedError => _feedError;

  PublicProfileModel? get currentInfo => _currentInfo;
  List<String> get currentPostIds => _currentPostIds;
  bool get hasMoreFeed => _hasMoreFeed;

  void setCurrentUser(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    if (_profileCache.containsKey(userId)) {
      final cache = _profileCache[userId]!;
      _currentInfo = cache.info;
      _currentPostIds = cache.postIds;
      _hasMoreFeed = true;
    } else {
      _currentInfo = null;
      _currentPostIds = [];
      _hasMoreFeed = true;
    }
    _infoError = null;
    _feedError = null;
    notifyListeners();
  }

  Future<void> fetchProfileInfo() async {
    final uid = _currentUserId;
    if (uid == null) return;

    _isLoadingInfo = true;
    _infoError = null;
    notifyListeners();

    final result = await _publicProfileService.getPublicProfile(uid);
    if (result.success && result.data != null) {
      if (_currentUserId == uid) {
        _currentInfo = result.data!;
        _updateCache(uid);
      }
    } else {
      if (_currentUserId == uid) {
        _infoError = result.message ?? 'Error al obtener información';
      }
    }
    _isLoadingInfo = false;
    notifyListeners();
  }

  Future<void> fetchInitialFeed() async {
    final uid = _currentUserId;
    if (uid == null) return;

    _isLoadingFeed = true;
    _feedError = null;
    _currentFeedPage = 1;
    _hasMoreFeed = true;
    notifyListeners();

    final result = await _publicProfileService.getPublicProfileFeed(uid, page: _currentFeedPage, limit: 15);
    if (result.success && result.data != null) {
      if (_currentUserId == uid) {
        final posts = result.data!['items'] as List<PostModel>;
        _hasMoreFeed = result.data!['hasMore'] as bool;

        // Ingest into global PostStoreProvider
        _postStore.addBatchPosts(posts);

        _currentPostIds = posts.map((p) => p.id).toList();
        _updateCache(uid);
      }
    } else {
      if (_currentUserId == uid) {
        _feedError = result.message ?? 'Error al obtener publicaciones';
      }
    }
    _isLoadingFeed = false;
    notifyListeners();
  }

  Future<void> fetchMoreFeed() async {
    final uid = _currentUserId;
    if (uid == null || _isLoadingMoreFeed || !_hasMoreFeed) return;

    _isLoadingMoreFeed = true;
    notifyListeners();

    _currentFeedPage++;
    final result = await _publicProfileService.getPublicProfileFeed(uid, page: _currentFeedPage, limit: 15);
    if (result.success && result.data != null) {
      if (_currentUserId == uid) {
        final posts = result.data!['items'] as List<PostModel>;
        _hasMoreFeed = result.data!['hasMore'] as bool;

        // Ingest into global PostStoreProvider
        _postStore.addBatchPosts(posts);

        _currentPostIds.addAll(posts.map((p) => p.id));
        _updateCache(uid);
      }
    } else {
      _currentFeedPage--; // Revert page increment on error
    }
    _isLoadingMoreFeed = false;
    notifyListeners();
  }

  void _updateCache(String userId) {
    final info = _currentInfo;
    if (info == null) return;
    _profileCache[userId] = PublicProfileCache(
      info: info,
      postIds: List.from(_currentPostIds),
      timestamp: DateTime.now(),
    );
  }
}
