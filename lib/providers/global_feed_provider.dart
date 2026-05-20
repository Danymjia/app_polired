import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/post_service.dart';
import 'post_store_provider.dart';

class GlobalFeedProvider extends ChangeNotifier {
  final PostService _postService;
  final PostStoreProvider _postStore;
  static const int _defaultLimit = 20;

  GlobalFeedProvider(this._postService, this._postStore);

  final List<String> _postIds = [];
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  String _selectedCategory = 'noticias';

  List<String> get postIds => List.unmodifiable(_postIds);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  Future<void> loadInitial({String category = 'noticias'}) async {
    if (_isLoadingInitial || _isLoadingMore) return;

    _selectedCategory = category;
    _isLoadingInitial = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    final result = await _loadFeedForCategory(
      category,
      page: _currentPage,
      limit: _defaultLimit,
    );

    if (result.success && result.data != null) {
      final newPosts = result.data!;
      _postStore.mergePosts(newPosts);
      
      _postIds
        ..clear()
        ..addAll(_removeDuplicatePosts(newPosts.map((p) => p.id).toList()));
      _hasMore = newPosts.length >= _defaultLimit;
    } else {
      _errorMessage = result.message ?? 'Error al cargar el feed';
      _postIds.clear();
      _hasMore = false;
    }

    _isLoadingInitial = false;
    notifyListeners();
  }

  Future<void> setCategory(String category) async {
    if (_selectedCategory == category) return;
    await loadInitial(category: category);
  }

  Future<void> refreshFeed() async {
    await loadInitial(category: _selectedCategory);
  }

  Future<void> loadMore() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await _loadFeedForCategory(
      _selectedCategory,
      page: nextPage,
      limit: _defaultLimit,
    );

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
      _errorMessage =
          result.message ?? 'No se pudieron cargar más publicaciones';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<ApiResult<List<PostModel>>> _loadFeedForCategory(
    String category, {
    required int page,
    required int limit,
  }) async {
    final key = category.toLowerCase();
    if (key == 'noticias') {
      return _postService.fetchGlobalFeed(page: page, limit: limit);
    }
    if (key == 'marketplace') {
      return _postService.fetchArticlesFeed(
        page: page,
        limit: limit,
        categoria: 'venta',
      );
    }
    if (key == 'cursos') {
      return _postService.fetchArticlesFeed(
        page: page,
        limit: limit,
        categoria: 'cursos',
      );
    }
    return _postService.fetchGlobalFeed(page: page, limit: limit);
  }

  List<String> _removeDuplicatePosts(List<String> ids) {
    final existingIds = _postIds.toSet();
    return ids.where((id) => !existingIds.contains(id)).toList();
  }
}
