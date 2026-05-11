import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

/// Estado de autenticación de la aplicación.
enum AuthStatus { loading, authenticated, unauthenticated }

/// Provider central de autenticación.
/// Expone el estado del usuario y métodos para login/register/logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SocketService _socketService;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider({
    required AuthService authService,
    required SocketService socketService,
  })  : _authService = authService,
        _socketService = socketService {
    _init();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  // ─── Inicialización ───────────────────────────────────────────────────────
  /// Verifica si hay sesión guardada al iniciar la app.
  Future<void> _init() async {
    final token = StorageService.getToken();
    final userData = StorageService.getUser();

    if (token != null && userData != null) {
      try {
        // Inyectar token al api service via método público
        _authService.initToken(token);
        _user = UserModel.fromJson(userData);
        _status = AuthStatus.authenticated;
        // Conectar socket con el ID del usuario
        _socketService.connect(_user!.id);
      } catch (_) {
        await _clearSession();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result.success && result.data != null) {
      final userData = result.data!['usuario'] as Map<String, dynamic>?;
      if (userData != null) {
        _user = UserModel.fromJson(userData);
        _status = AuthStatus.authenticated;
        _socketService.connect(_user!.id);
        notifyListeners();
        return true;
      }
    }

    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  // ─── Registro ─────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    return await _authService.register(
      nombre: nombre,
      apellido: apellido,
      email: email,
      password: password,
    );
  }

  // ─── Completar Perfil ──────────────────────────────────────────────────────
  Future<bool> completarPerfil(String username, {String? fotoPerfil}) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.completarPerfil(username, fotoPerfil: fotoPerfil);
    if (result.success) {
      final userData = StorageService.getUser();
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      notifyListeners();
      return true;
    }
    
    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  // ─── Recuperar contraseña ─────────────────────────────────────────────────
  Future<AuthResult> forgotPassword(String email) async {
    return await _authService.forgotPassword(email);
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _socketService.disconnect();
    await _authService.logout();
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    await StorageService.clear();
  }
}
