import 'package:flutter/material.dart';
import '../models/public_user_model.dart';
import '../services/explore_user_service.dart';

enum ExploreUsersStatus { idle, loading, success, error }

class ExploreUsersProvider extends ChangeNotifier {
  final ExploreUserService _exploreUserService;

  ExploreUsersProvider(this._exploreUserService);

  ExploreUsersStatus _status = ExploreUsersStatus.idle;
  String? _errorMessage;

  final List<PublicUserModel> _allUsers = [];
  List<PublicUserModel> _filteredUsers = [];
  String _searchQuery = '';

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  ExploreUsersStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PublicUserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _status == ExploreUsersStatus.loading;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

  Future<void> fetchInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    _status = ExploreUsersStatus.loading;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _allUsers.clear();
    _filteredUsers.clear();
    notifyListeners();

    final result = await _exploreUserService.getUsers(page: _currentPage, limit: 15);
    if (result.success && result.data != null) {
      final items = result.data!['items'] as List<PublicUserModel>;
      _hasMore = result.data!['hasMore'] as bool;
      _allUsers.addAll(items);
      _filterUsers();
      _status = ExploreUsersStatus.success;
    } else {
      _status = ExploreUsersStatus.error;
      _errorMessage = result.message ?? 'Error al cargar estudiantes';
    }
    _isFetching = false;
    notifyListeners();
  }

  Future<void> fetchMore() async {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;
    notifyListeners();

    _currentPage++;
    final result = await _exploreUserService.getUsers(page: _currentPage, limit: 15);
    if (result.success && result.data != null) {
      final items = result.data!['items'] as List<PublicUserModel>;
      _hasMore = result.data!['hasMore'] as bool;
      _allUsers.addAll(items);
      _filterUsers();
    } else {
      _currentPage--; // Revert page increment on error
    }
    _isFetching = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterUsers();
    notifyListeners();
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        final matchName = user.nombreCompleto.toLowerCase().contains(_searchQuery);
        final matchUsername = user.username.toLowerCase().contains(_searchQuery);
        return matchName || matchUsername;
      }).toList();
    }
  }
}
