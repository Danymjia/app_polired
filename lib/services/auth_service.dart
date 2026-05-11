import '../config/constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Resultado del proceso de autenticación.
class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const AuthResult({required this.success, this.message, this.data});
}

/// Servicio de autenticación: login, registro y recuperación de contraseña.
/// Se comunica con el backend usando [ApiService].
class AuthService {
  final ApiService _api;

  AuthService(this._api);

  /// Inyectar token guardado (llamado al restaurar sesión).
  void initToken(String token) => _api.setToken(token);

  /// Login con email y password.
  /// Backend: POST /api/auth/login
  Future<AuthResult> login(String email, String password) async {
    final result = await _api.post(AppConstants.loginEndpoint, {
      'email': email.trim().toLowerCase(),
      'password': password,
      'context': 'mobile',
    });

    if (result.success && result.data != null) {
      final token = result.data!['token'] as String?;
      final user = result.data!['usuario'] as Map<String, dynamic>?;

      if (token != null && user != null) {
        await StorageService.saveToken(token);
        await StorageService.saveUser(user);
        _api.setToken(token);
        return AuthResult(success: true, data: result.data);
      }
    }

    return AuthResult(success: false, message: result.message ?? 'Error al iniciar sesión');
  }

  /// Registro de nuevo estudiante.
  /// Backend: POST /api/registro-estudiantes
  Future<AuthResult> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final result = await _api.post(AppConstants.registroEndpoint, {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    if (result.success) {
      return AuthResult(success: true, message: result.data?['msg'] as String?);
    }

    return AuthResult(success: false, message: result.message ?? 'Error al registrar');
  }

  /// Envío de correo para recuperar contraseña.
  /// Backend: POST /api/recuperar-password-e
  Future<AuthResult> forgotPassword(String email) async {
    final result = await _api.post(AppConstants.recuperarPasswordEndpoint, {
      'email': email.trim().toLowerCase(),
    });

    if (result.success) {
      return AuthResult(success: true, message: result.data?['msg'] as String?);
    }

    return AuthResult(success: false, message: result.message ?? 'Error al enviar correo');
  }

  /// Obtener perfil del usuario autenticado.
  /// Backend: GET /api/perfil-estudiante
  Future<Map<String, dynamic>?> getPerfil() async {
    final result = await _api.get(AppConstants.perfilEndpoint);
    if (result.success && result.data is Map<String, dynamic>) {
      return result.data as Map<String, dynamic>;
    }
    return null;
  }

  /// Cerrar sesión: limpiar token local.
  Future<void> logout() async {
    _api.setToken(null);
    await StorageService.clear();
  }
}
