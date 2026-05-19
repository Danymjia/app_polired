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
  /// IDs de posts con operaciones optimistas en vuelo (evita sobrescribir
  /// estado local con datos obsoletos del backend durante una recarga concurrente).
  final Set<String> _pendingOptimistic = {};

  // ─── Getters ───────────────────────────────────────────────────────────────
  PostModel? getPost(String id) => _postsById[id];

  Map<String, PostModel> get postsById => Map.unmodifiable(_postsById);

  // ─── Ingesta de posts ──────────────────────────────────────────────────────
  /// Agrega o actualiza múltiples posts en el store.
  ///
  /// Estrategia de merge:
  /// - Si el post no existe → se agrega tal cual.
  /// - Si el post ya existe y NO tiene operaciones optimistas pendientes →
  ///   el backend es la fuente de verdad (incluido likedByMe / savedByMe).
  /// - Si el post tiene una operación optimista en vuelo → el estado local
  ///   prevalece para likedByMe/savedByMe/likesCount, pero se actualizan
  ///   commentsCount y otros metadatos del backend.
  void addPosts(List<PostModel> posts) {
    bool changed = false;
    for (final post in posts) {
      if (post.id.isEmpty) continue;
      final existing = _postsById[post.id];
      if (existing == null) {
        _postsById[post.id] = post;
        changed = true;
      } else {
        final PostModel merged;
        if (_pendingOptimistic.contains(post.id)) {
          // Operación en vuelo: conservar estado social local, actualizar
          // sólo commentsCount del backend (más fresco).
          merged = existing.copyWith(
            commentsCount: post.commentsCount,
          );
        } else {
          // Sin operaciones pendientes: el backend es la fuente de verdad.
          merged = post;
        }
        if (existing != merged) {
          _postsById[post.id] = merged;
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

    // Marcar como pendiente ANTES del optimistic update
    _pendingOptimistic.add(postId);

    // Optimistic update
    final wasLiked = post.likedByMe;
    _postsById[postId] = post.copyWith(
      likedByMe: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    notifyListeners();

    // Llamada al backend
    final success = await _postService.toggleLike(postId, wasLiked);

    // Quitar marca de pendiente
    _pendingOptimistic.remove(postId);

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

    // Marcar como pendiente ANTES del optimistic update
    _pendingOptimistic.add(postId);

    // Optimistic update
    final wasSaved = post.savedByMe;
    _postsById[postId] = post.copyWith(savedByMe: !wasSaved);
    notifyListeners();

    // Llamada al backend
    final success = await _postService.toggleSave(postId, wasSaved);

    // Quitar marca de pendiente
    _pendingOptimistic.remove(postId);

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
