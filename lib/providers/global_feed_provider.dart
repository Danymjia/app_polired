import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class GlobalFeedProvider extends ChangeNotifier {
  final PostService _postService;
  static const int _defaultLimit = 20;

  GlobalFeedProvider(this._postService);

  final List<PostModel> _posts = [];
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  List<PostModel> get posts => List.unmodifiable(_posts);
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

    final result = await _postService.fetchGlobalFeed(page: _currentPage, limit: _defaultLimit);

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _posts
        ..clear()
        ..addAll(_removeDuplicatePosts(newPosts));
      if (newPosts.length < _defaultLimit) {
        _hasMore = false;
      }
    } else {
      _errorMessage = result.message ?? 'Error al cargar el feed global';
      _posts.clear();
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
    final result = await _postService.fetchGlobalFeed(page: nextPage, limit: _defaultLimit);

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      final filteredPosts = _removeDuplicatePosts(newPosts);
      if (filteredPosts.isNotEmpty) {
        _posts.addAll(filteredPosts);
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

  List<PostModel> _removeDuplicatePosts(List<PostModel> posts) {
    final existingIds = _posts.map((post) => post.id).toSet();
    return posts.where((post) => !existingIds.contains(post.id)).toList();
  }
}
