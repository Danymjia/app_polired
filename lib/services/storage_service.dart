import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

/// Responsabilidad principal:
/// Capa de abstracción estática para la persistencia local de datos sensibles clave-valor.
/// Utiliza `flutter_secure_storage` para proteger la sesión (JWT) y PII del usuario.
///
/// Flujo dentro de la app:
/// Inicializado de forma bloqueante en `main.dart`. Consumido globalmente por `AuthService`, `AuthProvider`, y `ChatProvider`.
class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  // Caché en memoria para mantener lecturas síncronas sin romper consumidores
  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;

  static Future<void> init() async {
    // Pre-cargar datos sensibles en memoria desde Secure Storage
    _cachedToken = await _secureStorage.read(key: AppConstants.tokenKey);
    
    final rawUser = await _secureStorage.read(key: AppConstants.userKey);
    if (rawUser != null) {
      try {
        _cachedUser = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _cachedUser = null;
      }
    }
  }

  // ─── Token (Secure) ──────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    _cachedToken = token; // Update cache
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  static String? getToken() => _cachedToken; // Lectura síncrona

  static Future<void> removeToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // ─── Usuario (Secure) ────────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    _cachedUser = user; // Update cache
    await _secureStorage.write(key: AppConstants.userKey, value: jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() => _cachedUser; // Lectura síncrona

  static Future<void> removeUser() async {
    _cachedUser = null;
    await _secureStorage.delete(key: AppConstants.userKey);
  }

  // ─── Clear all ───────────────────────────────────────────────────────────
  static Future<void> clear() async {
    _cachedToken = null;
    _cachedUser = null;
    await _secureStorage.deleteAll();
  }
}
