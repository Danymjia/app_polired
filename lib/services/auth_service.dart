import 'dart:io';
import 'package:http/http.dart' as http;
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
      final dataMap = result.data as Map<String, dynamic>;
      final token = dataMap['token'] as String?;
      final user = dataMap['usuario'] as Map<String, dynamic>?;

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
      final dataMap = result.data as Map<String, dynamic>?;
      return AuthResult(success: true, message: dataMap?['msg'] as String?);
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
      final dataMap = result.data as Map<String, dynamic>?;
      return AuthResult(success: true, message: dataMap?['msg'] as String?);
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

  /// Completar perfil (username, fotoPerfil y biografía opcionales)
  /// Backend: PATCH /api/completar/perfil
  Future<AuthResult> completarPerfil(
    String username, {
    String? fotoPerfil,
    String? biografia,
    File? imageFile,
  }) async {
    if (imageFile != null) {
      final fields = <String, String>{
        'username': username.trim(),
        if (biografia != null && biografia.trim().isNotEmpty)
          'biografia': biografia.trim(),
      };
      final files = <http.MultipartFile>[
        await http.MultipartFile.fromPath('imagen', imageFile.path),
      ];
      final result = await _api.multipartRequest(
        AppConstants.completarPerfilEndpoint,
        method: 'PATCH',
        fields: fields,
        files: files,
      );

      if (result.success) {
        final dataMap = result.data as Map<String, dynamic>?;
        if (dataMap != null && dataMap['usuario'] != null) {
          await StorageService.saveUser(dataMap['usuario'] as Map<String, dynamic>);
        }
        return AuthResult(success: true, message: dataMap?['msg'] as String?);
      }
      return AuthResult(success: false, message: result.message ?? 'Error al completar perfil');
    }

    final body = <String, dynamic>{
      'username': username.trim(),
    };
    if (fotoPerfil != null && fotoPerfil.isNotEmpty) {
      body['fotoPerfil'] = fotoPerfil;
    }
    if (biografia != null && biografia.trim().isNotEmpty) {
      body['biografia'] = biografia.trim();
    }

    final result = await _api.patch(AppConstants.completarPerfilEndpoint, body);
    
    if (result.success) {
      // update local user with complete profile
      final dataMap = result.data as Map<String, dynamic>?;
      if (dataMap != null && dataMap['usuario'] != null) {
        await StorageService.saveUser(dataMap['usuario'] as Map<String, dynamic>);
      }
      return AuthResult(success: true, message: dataMap?['msg'] as String?);
    }
    
    return AuthResult(success: false, message: result.message ?? 'Error al completar perfil');
  }

  /// Actualizar nombre, apellido y biografía del estudiante autenticado.
  /// Backend: PATCH /api/estudiante/:id
  Future<AuthResult> actualizarDatosPerfilEstudiante({
    required String estudianteId,
    required String nombre,
    required String apellido,
    required String biografia,
    File? imageFile,
  }) async {
    if (imageFile != null) {
      final fields = <String, String>{
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'biografia': biografia.trim(),
      };
      final files = <http.MultipartFile>[
        await http.MultipartFile.fromPath('imagen', imageFile.path),
      ];
      final result = await _api.multipartRequest(
        '/estudiante/$estudianteId',
        method: 'PATCH',
        fields: fields,
        files: files,
      );

      if (result.success) {
        return AuthResult(success: true);
      }
      return AuthResult(success: false, message: result.message ?? 'Error al actualizar el perfil');
    }

    final result = await _api.patch('/estudiante/$estudianteId', {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'biografia': biografia.trim(),
    });
    if (result.success) {
      return AuthResult(success: true);
    }
    return AuthResult(success: false, message: result.message ?? 'Error al actualizar el perfil');
  }

  /// Actualizar nombre de usuario (perfil ya completo).
  /// Backend: PATCH /api/perfil/username
  Future<AuthResult> actualizarUsername(String username) async {
    final result = await _api.patch(AppConstants.perfilUsernameEndpoint, {
      'username': username.trim(),
    });
    if (result.success) {
      return AuthResult(success: true);
    }
    return AuthResult(success: false, message: result.message ?? 'Error al actualizar el usuario');
  }

  /// Sincroniza el usuario local con GET /perfil-estudiante.
  Future<AuthResult> refreshUserFromPerfil() async {
    final result = await _api.get(AppConstants.perfilEndpoint);
    if (result.success && result.data != null) {
      final raw = result.data;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        await StorageService.saveUser(map);
        return AuthResult(success: true, data: map);
      }
      return AuthResult(success: false, message: 'Respuesta inválida del servidor');
    }
    return AuthResult(success: false, message: result.message ?? 'No se pudo cargar el perfil');
  }

  /// Cerrar sesión: limpiar token local.
  Future<void> logout() async {
    _api.setToken(null);
    await StorageService.clear();
  }
}
