import 'package:flutter/material.dart';
import '../services/post_service.dart';

import 'post_store_provider.dart';

class CommunityFeedProvider extends ChangeNotifier {
  final PostService _postService;
  final PostStoreProvider _postStore;
  static const int _defaultLimit = 20;

  CommunityFeedProvider(this._postService, this._postStore);

  final List<String> _postIds = [];
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  List<String> get postIds => List.unmodifiable(_postIds);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitial() async {
    if (_isLoadingInitial || _isLoadingMore) return;

    _isLoadingInitial = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    final result = await _postService.fetchCommunityFeed(page: _currentPage, limit: _defaultLimit);

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _postStore.mergePosts(newPosts);
      
      _postIds
        ..clear()
        ..addAll(_removeDuplicatePosts(newPosts.map((p) => p.id).toList()));
      if (newPosts.length < _defaultLimit) {
        _hasMore = false;
      }
    } else {
      _errorMessage = result.message ?? 'Error al cargar el feed de comunidades';
      _postIds.clear();
      _hasMore = false;
    }

    _isLoadingInitial = false;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await _postService.fetchCommunityFeed(page: nextPage, limit: _defaultLimit);

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _postStore.mergePosts(newPosts);

      final filteredIds = _removeDuplicatePosts(newPosts.map((p) => p.id).toList());
      if (filteredIds.isNotEmpty) {
        _postIds.addAll(filteredIds);
      }
      if (newPosts.length < _defaultLimit) {
        _hasMore = false;
      }
      if (newPosts.isNotEmpty) {
        _currentPage = nextPage;
      }
    } else {
      _errorMessage = result.message ?? 'No se pudieron cargar más publicaciones';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  List<String> _removeDuplicatePosts(List<String> ids) {
    final existingIds = _postIds.toSet();
    return ids.where((id) => !existingIds.contains(id)).toList();
  }

  // ─── Mutadores Síncronos (Optimistic UI) ───────────────────────────────────

  void prependPostId(String id) {
    if (!_postIds.contains(id)) {
      _postIds.insert(0, id);
      notifyListeners();
    }
  }

  int removePostId(String id) {
    final index = _postIds.indexOf(id);
    if (index != -1) {
      _postIds.removeAt(index);
      notifyListeners();
    }
    return index;
  }

  void insertPostId(int index, String id) {
    if (index < 0) return;
    if (!_postIds.contains(id)) {
      final insertIndex = index.clamp(0, _postIds.length);
      _postIds.insert(insertIndex, id);
      notifyListeners();
    }
  }

  void replacePostId(String oldId, String newId) {
    final index = _postIds.indexOf(oldId);
    if (index != -1) {
      _postIds[index] = newId;
      notifyListeners();
    }
  }
}
