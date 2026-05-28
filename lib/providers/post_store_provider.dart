import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/events/post_event.dart';
import '../models/feed_context.dart';

/// PostStoreProvider (Snapshot-Safe CQRS Store)
/// 
/// Responsabilidades estrictas:
/// - State Management (almacena PostModel)
/// - Idempotencia global (Única fuente de verdad de eventos procesados)
/// - Indexación O(1) de listas por contexto
/// 
/// NULA lógica de negocio o de red. Solo guarda estado y orquesta caché.
class PostStoreProvider extends ChangeNotifier {
  // ─── Estado normalizado ────────────────────────────────────────────────────
  final Map<String, PostModel> _postsById = {};
  final Map<FeedContext, Set<String>> _contextIndex = {};
  
  final Set<String> _likedPostIds = {};
  final Set<String> _savedPostIds = {};
  bool _isSocialStateInitialized = false;

  // ─── Event Stream (UI Events) ──────────────────────────────────────────────
  final _uiEventController = StreamController<UIEvent>.broadcast();
  Stream<UIEvent> get uiEvents => _uiEventController.stream;

  // ─── Versionamiento Dual ───────────────────────────────────────────────────
  int _globalVersion = 0; // Cambia con CUALQUIER mutación
  final Map<FeedContext, int> _contextVersion = {};
  
  // ─── Idempotencia ──────────────────────────────────────────────────────────
  final Map<FeedContext, Set<String>> _processedEvents = {};
  final Map<FeedContext, int> _lastSequenceNumber = {};

  int get globalVersion => _globalVersion;
  bool get isSocialStateInitialized => _isSocialStateInitialized;

  // ─── Getters Crudos ────────────────────────────────────────────────────────
  PostModel? getPost(String id) => _postsById[id];
  Map<String, PostModel> get postsById => Map.unmodifiable(_postsById);
  Set<String> get likedPostIds => Set.unmodifiable(_likedPostIds);
  Set<String> get savedPostIds => Set.unmodifiable(_savedPostIds);

  /// Índice de IDs por contexto. O(1).
  Set<String> getContextIndex(FeedContext context) {
    return _contextIndex[context] ?? const {};
  }

  /// Retorna los contextos a los que pertenece un post
  List<FeedContext> getContextsForPost(String postId) {
    return _contextIndex.entries
        .where((e) => e.value.contains(postId))
        .map((e) => e.key)
        .toList();
  }

  /// Fingerprint = string único por contexto. O(1) en lectura.
  String getFingerprint(FeedContext context) {
    final v = _contextVersion[context] ?? 0;
    return '${context.name}-$v';
  }

  /// O(1) — Solo incrementa el contador del contexto afectado
  void _bumpVersion(FeedContext context) {
    _globalVersion++;
    _contextVersion[context] = (_contextVersion[context] ?? 0) + 1;
  }

  int nextSequenceNumber(FeedContext context) {
    return (_lastSequenceNumber[context] ?? -1) + 1;
  }

  // ─── Hidratación Social Base ───────────────────────────────────────────────
  void setSocialHydration(List<String> likedIds, List<String> savedIds) {
    _likedPostIds.clear();
    _savedPostIds.clear();
    _likedPostIds.addAll(likedIds);
    _savedPostIds.addAll(savedIds);
    _isSocialStateInitialized = true;
    _globalVersion++;
    notifyListeners();
  }

  // ─── Limpieza (Logout) ─────────────────────────────────────────────────────
  void clear() {
    _postsById.clear();
    _contextIndex.clear();
    _likedPostIds.clear();
    _savedPostIds.clear();
    _contextVersion.clear();
    _processedEvents.clear();
    _lastSequenceNumber.clear();
    _isSocialStateInitialized = false;
    _globalVersion++;
    notifyListeners();
  }

  // ─── Aplicadores de Eventos (State) ────────────────────────────────────────
  
  /// Retorna false si el evento debe ignorarse.
  bool _shouldProcess(StateEvent event) {
    final context = event.context;
    final processed = _processedEvents[context] ??= {};
    final lastSeq = _lastSequenceNumber[context] ?? -1;

    // Rechazar duplicado por eventId
    if (processed.contains(event.eventId)) return false;
    
    // Rechazar evento fuera de orden (stale)
    if (event.sequenceNumber <= lastSeq) return false;

    processed.add(event.eventId);
    _lastSequenceNumber[context] = event.sequenceNumber;
    return true;
  }

  void applyPostCreated(PostCreated event) {
    if (!_shouldProcess(event)) return;
    
    final post = event.post;
    _postsById[post.id] = post;
    
    // Añadir al inicio del Set para que aparezca arriba en el feed
    final currentSet = _contextIndex[event.context] ?? <String>{};
    _contextIndex[event.context] = <String>{post.id, ...currentSet};
    
    _bumpVersion(event.context);
    notifyListeners();
  }

  void applyPostDeleted(PostDeleted event) {
    if (!_shouldProcess(event)) return;
    
    _postsById.remove(event.postId);
    _contextIndex[event.context]?.remove(event.postId);
    _likedPostIds.remove(event.postId);
    _savedPostIds.remove(event.postId);
    _bumpVersion(event.context);
    notifyListeners();
  }

  void applyPostUpdated(PostUpdated event) {
    if (!_shouldProcess(event)) return;
    
    if (_postsById.containsKey(event.post.id)) {
      _postsById[event.post.id] = event.post;
      _bumpVersion(event.context); // Fingerprint cambia aunque el índice no
      notifyListeners();
    }
  }

  void applyStateEvent(StateEvent event) {
    if (event is PostCreated) {
      applyPostCreated(event);
    } else if (event is PostDeleted) {
      applyPostDeleted(event);
    } else if (event is PostUpdated) {
      applyPostUpdated(event);
    }
  }

  // ─── Emisión de UI Events ──────────────────────────────────────────────────
  void emitUIEvent(UIEvent event) {
    _uiEventController.add(event);
    if (event is PostInteractionUpdated) {
      final post = _postsById[event.postId];
      if (post != null) {
        _postsById[event.postId] = post.copyWith(
          likedByMe: event.liked,
          likesCount: event.likeCount,
          savedByMe: event.saved,
          commentsCount: event.commentCount,
        );
        if (event.liked) {
          _likedPostIds.add(event.postId);
        } else {
          _likedPostIds.remove(event.postId);
        }
        if (event.saved) {
          _savedPostIds.add(event.postId);
        } else {
          _savedPostIds.remove(event.postId);
        }
        _globalVersion++;
        
        // Find which contexts this post belongs to, and bump them
        for (final context in _contextIndex.keys) {
          if (_contextIndex[context]?.contains(event.postId) ?? false) {
             _contextVersion[context] = (_contextVersion[context] ?? 0) + 1;
          }
        }
        notifyListeners();
      }
    }
  }

  // ─── Ingesta Batch ─────────────────────────────────────────────────────────
  void addBatchPosts(List<PostModel> posts, {FeedContext? context}) {
    bool changed = false;
    for (final post in posts) {
      if (post.id.isEmpty) continue;
      _postsById[post.id] = post.copyWith(
        likedByMe: _likedPostIds.contains(post.id) || post.likedByMe,
        savedByMe: _savedPostIds.contains(post.id) || post.savedByMe,
      );
      
      if (context != null) {
        (_contextIndex[context] ??= {}).add(post.id);
      }
      changed = true;
    }
    if (changed) {
      _globalVersion++;
      if (context != null) {
        _contextVersion[context] = (_contextVersion[context] ?? 0) + 1;
      }
      notifyListeners();
    }
  }

  // ─── Incrementar contador de comentarios ───────────────────────────────────
  void incrementCommentsCount(String postId) {
    final post = _postsById[postId];
    if (post == null) return;
    _postsById[postId] = post.copyWith(commentsCount: post.commentsCount + 1);
    _globalVersion++;
    for (final context in _contextIndex.keys) {
      if (_contextIndex[context]?.contains(postId) ?? false) {
         _contextVersion[context] = (_contextVersion[context] ?? 0) + 1;
      }
    }
    notifyListeners();
  }

  // Compatibilidad antigua (proyección obsoleta, se mantendrá hasta que
  // los providers cambien a FeedSelectors para no romper el build)
  int get feedVersionHome => _contextVersion[FeedContext.home()] ?? 0;
  int get feedVersionGlobal => _contextVersion[FeedContext.exploreGlobal()] ?? 0;
  
  void incrementFeedVersionHome() {
    _bumpVersion(FeedContext.home());
    notifyListeners();
  }

  void incrementFeedVersionGlobal() {
    _bumpVersion(FeedContext.exploreGlobal());
    notifyListeners();
  }
  
  int getNetworkFeedVersion(String networkId) => _contextVersion[FeedContext.home()] ?? 0;
  
  void incrementFeedVersionNetwork(String networkId) {
    _bumpVersion(FeedContext.home());
    notifyListeners();
  }

  List<PostModel> resolvePosts(List<String> ids, int version) {
    return ids.map((id) => _postsById[id]).whereType<PostModel>().toList();
  }

  @override
  void dispose() {
    _uiEventController.close();
    super.dispose();
  }
}
