import 'package:flutter/material.dart';
import '../models/public_user_model.dart';
import '../services/explore_user_service.dart';

/// Responsabilidad principal:
/// Estado de paginación y filtrado en memoria de la lista pública de estudiantes (para la vista Explorar).
///
/// Flujo dentro de la app:
/// Pide páginas de usuarios al servidor y permite filtrarlos localmente (en el cliente).
///
/// Dependencias críticas:
/// - `ExploreUserService` (HTTP).
///
/// Side Effects:
/// - Ninguno. Estado aislado.
///
/// Recordatorios técnicos y CQRS:
/// - Deuda técnica grave (Búsqueda local): Descarga páginas del servidor pero realiza el filtrado de texto *en memoria* (`_allUsers.where()`). Buscar "Juan" solo lo encontrará si ya fue cargado en la página actual. Se DEBE migrar la búsqueda (Search Query) al Backend.
enum ExploreUsersStatus { idle, loading, success, error }

class ExploreUsersProvider extends ChangeNotifier {
  final ExploreUserService _exploreUserService;

  ExploreUsersProvider(this._exploreUserService);

  ExploreUsersStatus _status = ExploreUsersStatus.idle;
  String? _errorMessage;

  final List<PublicUserModel> _allUsers = [];
  List<PublicUserModel> _filteredUsers = [];
  String _searchQuery = '';
  String? _currentUserId;

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

  Future<void> fetchInitial({String? currentUserId}) async {
    if (currentUserId != null) _currentUserId = currentUserId;
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

  void search(String query, {String? currentUserId}) {
    if (currentUserId != null) _currentUserId = currentUserId;
    _searchQuery = query.toLowerCase();
    _filterUsers();
    notifyListeners();
  }

  void _filterUsers() {
    List<PublicUserModel> baseList = _allUsers;
    if (_currentUserId != null) {
      baseList = baseList.where((u) => u.id != _currentUserId).toList();
    }
    
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(baseList);
    } else {
      _filteredUsers = baseList.where((user) {
        final matchName = user.nombreCompleto.toLowerCase().contains(_searchQuery);
        final matchUsername = user.username.toLowerCase().contains(_searchQuery);
        return matchName || matchUsername;
      }).toList();
    }
  }
}
