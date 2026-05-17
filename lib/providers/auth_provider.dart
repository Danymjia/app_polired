import 'dart:io';
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
        // Socket.IO: el backend autentica con JWT en handshake.auth.token
        if (token.isNotEmpty) {
          _socketService.connect(token);
        }
        notifyListeners();
        // El login guarda un `usuario` reducido (sin biografía). Refrescar desde el servidor
        // para que biografía y demás campos coincidan siempre con la base de datos.
        await _syncProfileFromServer();
      } catch (_) {
        await _clearSession();
        notifyListeners();
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// GET /perfil-estudiante → actualiza [_user] y almacenamiento local si la petición tiene éxito.
  Future<void> _syncProfileFromServer() async {
    final refresh = await _authService.refreshUserFromPerfil();
    if (refresh.success && refresh.data != null) {
      _user = UserModel.fromJson(refresh.data!);
      notifyListeners();
    }
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
        final token = StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          _socketService.connect(token);
        }
        notifyListeners();
        await _syncProfileFromServer();
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
  Future<bool> completarPerfil(
    String username, {
    String? fotoPerfil,
    String? biografia,
    File? imageFile,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.completarPerfil(
      username,
      fotoPerfil: fotoPerfil,
      biografia: biografia,
      imageFile: imageFile,
    );
    if (result.success) {
      final userData = StorageService.getUser();
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      await _syncProfileFromServer();
      notifyListeners();
      return true;
    }
    
    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  /// Actualiza nombre, apellido, biografía y username (este último si cambió).
  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String username,
    required String biografia,
    File? imageFile,
  }) async {
    final user = _user;
    if (user == null) return false;

    _errorMessage = null;
    notifyListeners();

    final datosResult = await _authService.actualizarDatosPerfilEstudiante(
      estudianteId: user.id,
      nombre: nombre,
      apellido: apellido,
      biografia: biografia,
      imageFile: imageFile,
    );
    if (!datosResult.success) {
      _errorMessage = datosResult.message;
      notifyListeners();
      return false;
    }

    final usernameActual = (user.username ?? '').trim();
    if (username.trim() != usernameActual) {
      final userResult = await _authService.actualizarUsername(username);
      if (!userResult.success) {
        _errorMessage = userResult.message;
        notifyListeners();
        return false;
      }
    }

    final refresh = await _authService.refreshUserFromPerfil();
    if (!refresh.success || refresh.data == null) {
      _errorMessage = refresh.message ?? 'No se pudo sincronizar el perfil';
      notifyListeners();
      return false;
    }

    _user = UserModel.fromJson(refresh.data!);
    notifyListeners();
    return true;
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
