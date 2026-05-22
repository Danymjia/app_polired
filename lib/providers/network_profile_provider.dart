import 'package:flutter/material.dart';
import '../models/network_profile_model.dart';
import '../models/post_model.dart';
import '../services/network_service.dart';
import 'post_store_provider.dart';

enum NetworkProfileStatus { idle, loading, success, error }

class NetworkProfileProvider extends ChangeNotifier {
  final NetworkService _networkService;
  final PostStoreProvider _postStore;
  
  NetworkProfileProvider(this._networkService, this._postStore);

  NetworkProfileStatus _status = NetworkProfileStatus.idle;
  String? _errorMessage;
  NetworkProfileModel? _profile;
  
  // Pagination
  List<String> _postIds = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  NetworkProfileStatus get status => _status;
  String? get errorMessage => _errorMessage;
  NetworkProfileModel? get profile => _profile;
  List<String> get postIds => _postIds;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadProfile(String networkId, {bool isMember = false}) async {
    _status = NetworkProfileStatus.loading;
    _errorMessage = null;
    _postIds = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    final result = await _networkService.getNetworkProfile(networkId, page: _currentPage, limit: 10);
    
    if (result.success && result.data != null) {
      final data = result.data!;
      _profile = NetworkProfileModel.fromApiMap(data['red'] as Map<String, dynamic>);
      
      final items = data['items'];
      if (items is List) {
        final newPosts = items.map((j) => PostModel.fromJson(j as Map<String, dynamic>)).toList();
        _postStore.mergePosts(newPosts);
        _postIds = newPosts.map((p) => p.id).toList();
      }
      
      _status = NetworkProfileStatus.success;
      
      // If not a member, we should not paginate beyond the first page.
      if (!isMember) {
        _hasMore = false;
      } else {
        final total = data['total'] as int? ?? 0;
        _hasMore = _postIds.length < total;
      }
    } else {
      _status = NetworkProfileStatus.error;
      _errorMessage = result.message ?? 'Error al cargar perfil de la red';
    }
    
    notifyListeners();
  }

  Future<void> loadMore(String networkId, {bool isMember = false}) async {
    if (!_hasMore || _isLoadingMore || !isMember) return;
    
    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    final result = await _networkService.getNetworkProfile(networkId, page: _currentPage, limit: 10);
    
    if (result.success && result.data != null) {
      final data = result.data!;
      final items = data['items'];
      
      if (items is List) {
        final newPosts = items.map((j) => PostModel.fromJson(j as Map<String, dynamic>)).toList();
        _postStore.mergePosts(newPosts);
        
        final filteredIds = newPosts.map((p) => p.id).where((id) => !_postIds.contains(id)).toList();
        if (filteredIds.isNotEmpty) {
          _postIds.addAll(filteredIds);
        }
        
        final total = data['total'] as int? ?? 0;
        _hasMore = _postIds.length < total;
      }
    } else {
      _hasMore = false;
    }
    
    _isLoadingMore = false;
    notifyListeners();
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
