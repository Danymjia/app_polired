import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/public_profile_service.dart';
import 'post_store_provider.dart';

class MyProfileFeedProvider extends ChangeNotifier {
  final PublicProfileService _publicProfileService;
  final PostStoreProvider _postStore;

  MyProfileFeedProvider(this._publicProfileService, this._postStore);

  bool _isLoadingFeed = false;
  bool _isLoadingMoreFeed = false;
  String? _feedError;
  List<String> _postIds = [];
  int _feedPage = 1;
  bool _hasMoreFeed = true;

  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  String? get feedError => _feedError;
  List<String> get postIds => _postIds;
  bool get hasMoreFeed => _hasMoreFeed;

  Future<void> fetchInitialFeed(String myUserId) async {
    _isLoadingFeed = true;
    _feedError = null;
    _feedPage = 1;
    _hasMoreFeed = true;
    notifyListeners();

    final result = await _publicProfileService.getPublicProfileFeed(myUserId, page: _feedPage, limit: 12);
    if (result.success && result.data != null) {
      final posts = result.data!['items'] as List<PostModel>;
      _hasMoreFeed = result.data!['hasMore'] as bool;

      _postStore.mergePosts(posts);
      _postIds = posts.map((p) => p.id).toList();
    } else {
      _feedError = result.message ?? 'Error al obtener publicaciones';
    }
    _isLoadingFeed = false;
    notifyListeners();
  }

  Future<void> fetchMoreFeed(String myUserId) async {
    if (_isLoadingMoreFeed || !_hasMoreFeed) return;

    _isLoadingMoreFeed = true;
    notifyListeners();

    _feedPage++;
    final result = await _publicProfileService.getPublicProfileFeed(myUserId, page: _feedPage, limit: 12);
    if (result.success && result.data != null) {
      final posts = result.data!['items'] as List<PostModel>;
      _hasMoreFeed = result.data!['hasMore'] as bool;

      _postStore.mergePosts(posts);
      _postIds.addAll(posts.map((p) => p.id));
    } else {
      _feedPage--;
    }
    _isLoadingMoreFeed = false;
    notifyListeners();
  }
}
