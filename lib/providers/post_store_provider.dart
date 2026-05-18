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

  // ─── Getters ───────────────────────────────────────────────────────────────
  PostModel? getPost(String id) => _postsById[id];

  Map<String, PostModel> get postsById => Map.unmodifiable(_postsById);

  // ─── Ingesta de posts ──────────────────────────────────────────────────────
  /// Agrega o actualiza múltiples posts en el store.
  /// Posts existentes NO se sobreescriben si ya tienen estado social actualizado
  /// (para no perder likes/saves optimistas).
  void addPosts(List<PostModel> posts) {
    bool changed = false;
    for (final post in posts) {
      if (post.id.isEmpty) continue;
      final existing = _postsById[post.id];
      if (existing == null) {
        _postsById[post.id] = post;
        changed = true;
      } else {
        // Actualizar métricas del backend, pero respetar estado social local
        // solo si el backend no trae datos más frescos
        final updated = post.copyWith(
          likedByMe: post.likedByMe || existing.likedByMe,
          savedByMe: post.savedByMe || existing.savedByMe,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount,
        );
        if (existing != updated) {
          _postsById[post.id] = updated;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  /// Agrega o actualiza un único post.
  void addPost(PostModel post) {
    if (post.id.isEmpty) return;
    _postsById[post.id] = post;
    notifyListeners();
  }

  // ─── Toggle Like (con optimistic update y rollback) ────────────────────────
  Future<void> toggleLike(String postId) async {
    final post = _postsById[postId];
    if (post == null) return;

    // Optimistic update
    final wasLiked = post.likedByMe;
    _postsById[postId] = post.copyWith(
      likedByMe: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    notifyListeners();

    // Llamada al backend
    final success = await _postService.toggleLike(postId, wasLiked);

    if (!success) {
      // Rollback
      final current = _postsById[postId];
      if (current != null) {
        _postsById[postId] = current.copyWith(
          likedByMe: wasLiked,
          likesCount: wasLiked ? current.likesCount + 1 : current.likesCount - 1,
        );
        notifyListeners();
      }
    }
  }

  // ─── Toggle Save (con optimistic update y rollback) ────────────────────────
  Future<void> toggleSave(String postId) async {
    final post = _postsById[postId];
    if (post == null) return;

    // Optimistic update
    final wasSaved = post.savedByMe;
    _postsById[postId] = post.copyWith(savedByMe: !wasSaved);
    notifyListeners();

    // Llamada al backend
    final success = await _postService.toggleSave(postId, wasSaved);

    if (!success) {
      // Rollback
      final current = _postsById[postId];
      if (current != null) {
        _postsById[postId] = current.copyWith(savedByMe: wasSaved);
        notifyListeners();
      }
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

  // ─── Limpiar store ─────────────────────────────────────────────────────────
  void clearStore() {
    _postsById.clear();
    notifyListeners();
  }
}
