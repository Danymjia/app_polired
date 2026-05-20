import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// Store global normalizado de publicaciones.
///
/// Todos los feeds (Home, Explore) almacenan únicamente [List<String>] de IDs.
/// Los [PostModel] reales viven aquí, en `_postsById`.
///
/// Garantiza:
///   - O(1) lookups por ID
///   - Sincronización global: un like en ExploreScreen se refleja en HomeScreen
///   - Optimistic updates con rollback automático
///   - Rerenders selectivos via context.select
class PostStoreProvider extends ChangeNotifier {
  final PostService _postService;

  PostStoreProvider(this._postService);

  // ─── Estado normalizado ────────────────────────────────────────────────────
  final Map<String, PostModel> _postsById = {};
  
  /// IDs de posts con operaciones optimistas en vuelo.
  final Set<String> _pendingOptimistic = {};

  /// Sets de hidratación social global (fuente de verdad absoluta en la app)
  final Set<String> _likedPostIds = {};
  final Set<String> _savedPostIds = {};
  bool _isSocialStateInitialized = false;

  bool get isSocialStateInitialized => _isSocialStateInitialized;

  // ─── Getters ───────────────────────────────────────────────────────────────
  PostModel? getPost(String id) => _postsById[id];

  Map<String, PostModel> get postsById => Map.unmodifiable(_postsById);

  Set<String> get likedPostIds => Set.unmodifiable(_likedPostIds);
  Set<String> get savedPostIds => Set.unmodifiable(_savedPostIds);

  // ─── Hidratación Inicial Global ──────────────────────────────────────────
  Future<void> initializeSocialState() async {
    try {
      bool loadedLikes = false;
      bool loadedSaves = false;

      // 1. Cargar publicaciones gustadas
      final likesResult = await _postService.fetchLikedPosts(page: 1, limit: 1000);
      if (likesResult.success && likesResult.data != null) {
        _likedPostIds.clear();
        for (final post in likesResult.data!) {
          _likedPostIds.add(post.id);
        }
        loadedLikes = true;
      }

      // 2. Cargar publicaciones guardadas
      final savedResult = await _postService.fetchSavedPosts();
      if (savedResult.success && savedResult.data != null) {
        _savedPostIds.clear();
        for (final post in savedResult.data!) {
          _savedPostIds.add(post.id);
        }
        loadedSaves = true;
      }

      if (loadedLikes && loadedSaves) {
        _isSocialStateInitialized = true;
      }

      // Sincronizar posts cargados actualmente en memoria
      _postsById.forEach((id, post) {
        final isLiked = _likedPostIds.contains(id);
        final isSaved = _savedPostIds.contains(id);
        if (post.likedByMe != isLiked || post.savedByMe != isSaved) {
          int finalLikesCount = post.likesCount;
          if (isLiked && !post.likedByMe) {
            finalLikesCount += 1;
          } else if (!isLiked && post.likedByMe) {
            finalLikesCount = (post.likesCount - 1).clamp(0, double.infinity).toInt();
          }

          _postsById[id] = post.copyWith(
            likedByMe: isLiked,
            savedByMe: isSaved,
            likesCount: finalLikesCount,
          );
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('PostStoreProvider.initializeSocialState: Error: $e');
    }
  }

  // ─── Lógica de Sincronización Social ───────────────────────────────────────
  PostModel syncSocialState(PostModel incoming, PostModel existing) {
    final String id = incoming.id;

    // Si hay una operación optimista en vuelo localmente, ignoramos el estado del backend
    if (_pendingOptimistic.contains(id)) {
      return existing.copyWith(
        commentsCount: incoming.commentsCount,
      );
    }

    // Siempre confiamos en cualquier "true" que mande el backend e hidratamos nuestro set local
    if (incoming.likedByMe) {
      _likedPostIds.add(id);
    }
    if (incoming.savedByMe) {
      _savedPostIds.add(id);
    }

    final isLiked = _likedPostIds.contains(id);
    final isSaved = _savedPostIds.contains(id);

    int finalLikesCount = incoming.likesCount;
    // Si localmente está como gustado, pero el backend (feed genérico) reporta que no,
    // ajustamos sumando 1 para evitar saltos.
    if (isLiked && !incoming.likedByMe) {
      if (existing.likesCount > incoming.likesCount) {
        finalLikesCount = existing.likesCount;
      } else {
        finalLikesCount = incoming.likesCount + 1;
      }
    } else if (!isLiked && incoming.likedByMe) {
      // Backend dice true pero ya desmarcamos localmente.
      finalLikesCount = (incoming.likesCount - 1).clamp(0, double.infinity).toInt();
    }

    return incoming.copyWith(
      likedByMe: isLiked,
      savedByMe: isSaved,
      likesCount: finalLikesCount,
    );
  }

  // ─── Ingesta de posts ──────────────────────────────────────────────────────
  
  /// Combina posts y los inserta de forma incremental en el store normalizado.
  List<PostModel> mergePosts(List<PostModel> posts) {
    bool changed = false;
    final List<PostModel> mergedList = [];
    for (final post in posts) {
      if (post.id.isEmpty) continue;

      if (post.likedByMe) _likedPostIds.add(post.id);
      if (post.savedByMe) _savedPostIds.add(post.id);

      final existing = _postsById[post.id];
      if (existing == null) {
        final synced = syncSocialState(post, post);
        _postsById[post.id] = synced;
        mergedList.add(synced);
        changed = true;
      } else {
        final synced = syncSocialState(post, existing);
        if (existing != synced) {
          _postsById[post.id] = synced;
          changed = true;
        }
        mergedList.add(synced);
      }
    }
    if (changed) notifyListeners();
    return mergedList;
  }

  void addPosts(List<PostModel> posts) {
    mergePosts(posts);
  }

  /// Inserta o actualiza un único post.
  void upsertPost(PostModel post) {
    if (post.id.isEmpty) return;

    if (post.likedByMe) _likedPostIds.add(post.id);
    if (post.savedByMe) _savedPostIds.add(post.id);

    final existing = _postsById[post.id];
    if (existing == null) {
      _postsById[post.id] = syncSocialState(post, post);
      notifyListeners();
    } else {
      final synced = syncSocialState(post, existing);
      if (existing != synced) {
        _postsById[post.id] = synced;
        notifyListeners();
      }
    }
  }

  void addPost(PostModel post) {
    upsertPost(post);
  }

  // ─── Toggle Like (con optimistic update y rollback) ────────────────────────
  Future<void> toggleLike(String postId) async {
    final post = _postsById[postId];
    if (post == null) return;

    _pendingOptimistic.add(postId);

    final wasLiked = _likedPostIds.contains(postId);
    if (wasLiked) {
      _likedPostIds.remove(postId);
      _postsById[postId] = post.copyWith(
        likedByMe: false,
        likesCount: (post.likesCount - 1).clamp(0, double.infinity).toInt(),
      );
    } else {
      _likedPostIds.add(postId);
      _postsById[postId] = post.copyWith(
        likedByMe: true,
        likesCount: post.likesCount + 1,
      );
    }
    notifyListeners();

    final success = await _postService.toggleLike(postId, wasLiked);

    _pendingOptimistic.remove(postId);

    if (!success) {
      // Rollback
      if (wasLiked) {
        _likedPostIds.add(postId);
      } else {
        _likedPostIds.remove(postId);
      }
      _postsById[postId] = post;
      notifyListeners();
    }
  }

  // ─── Toggle Save (con optimistic update y rollback) ────────────────────────
  Future<void> toggleSave(String postId) async {
    final post = _postsById[postId];
    if (post == null) return;

    _pendingOptimistic.add(postId);

    final wasSaved = _savedPostIds.contains(postId);
    if (wasSaved) {
      _savedPostIds.remove(postId);
      _postsById[postId] = post.copyWith(savedByMe: false);
    } else {
      _savedPostIds.add(postId);
      _postsById[postId] = post.copyWith(savedByMe: true);
    }
    notifyListeners();

    final success = await _postService.toggleSave(postId, wasSaved);

    _pendingOptimistic.remove(postId);

    if (!success) {
      // Rollback
      if (wasSaved) {
        _savedPostIds.add(postId);
      } else {
        _savedPostIds.remove(postId);
      }
      _postsById[postId] = post;
      notifyListeners();
    }
  }

  // ─── Incrementar contador de comentarios ───────────────────────────────────
  void incrementCommentsCount(String postId) {
    final post = _postsById[postId];
    if (post == null) return;
    _postsById[postId] = post.copyWith(commentsCount: post.commentsCount + 1);
    notifyListeners();
  }

  // ─── Actualizar commentsCount desde backend ────────────────────────────────
  void updateCommentsCount(String postId, int count) {
    final post = _postsById[postId];
    if (post == null) return;
    _postsById[postId] = post.copyWith(commentsCount: count);
    notifyListeners();
  }

  // ─── Evicción de Cache (Poda) ──────────────────────────────────────────────
  void pruneCache(List<List<String>> activeFeedIds) {
    final activeIds = activeFeedIds.expand((ids) => ids).toSet();
    // Protegemos me gusta y guardados locales
    activeIds.addAll(_likedPostIds);
    activeIds.addAll(_savedPostIds);

    final originalLength = _postsById.length;
    _postsById.removeWhere((id, post) => !activeIds.contains(id));
    if (_postsById.length != originalLength) {
      notifyListeners();
    }
  }

  // ─── Limpiar store ─────────────────────────────────────────────────────────
  void clearStore() {
    _postsById.clear();
    _likedPostIds.clear();
    _savedPostIds.clear();
    _pendingOptimistic.clear();
    _isSocialStateInitialized = false;
    notifyListeners();
  }
}
