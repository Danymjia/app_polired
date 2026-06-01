import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

/// Responsabilidad principal:
/// Capa de abstracción estática para la persistencia local de datos clave-valor usando `shared_preferences`.
///
/// Flujo dentro de la app:
/// Inicializado de forma bloqueante en `main.dart`. Consumido globalmente por `AuthService`, `AuthProvider`, y `NotificationProvider` para persistir estado entre reinicios.
///
/// Dependencias críticas:
/// - `shared_preferences`.
///
/// Side Effects:
/// - Persistencia: Realiza I/O en disco (asíncrono).
///
/// Recordatorios técnicos y CQRS:
/// - Riesgo de Seguridad: `SharedPreferences` guarda datos en texto plano. Almacenar el JWT (`saveToken`) directamente aquí expone la sesión en dispositivos rooteados. Deuda técnica: migrar a `flutter_secure_storage`.
class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Token ───────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  static String? getToken() => _prefs?.getString(AppConstants.tokenKey);

  static Future<void> removeToken() async {
    await _prefs?.remove(AppConstants.tokenKey);
  }

  // ─── Usuario ─────────────────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs?.setString(AppConstants.userKey, jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _prefs?.getString(AppConstants.userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeUser() async {
    await _prefs?.remove(AppConstants.userKey);
  }

  // ─── Preferencias de Notificaciones ────────────────────────────────────────
  static bool getNotifLikes() => _prefs?.getBool('notif_likes') ?? true;
  static Future<void> setNotifLikes(bool value) async => await _prefs?.setBool('notif_likes', value);

  static bool getNotifComments() => _prefs?.getBool('notif_comments') ?? true;
  static Future<void> setNotifComments(bool value) async => await _prefs?.setBool('notif_comments', value);

  static bool getNotifMessages() => _prefs?.getBool('notif_messages') ?? true;
  static Future<void> setNotifMessages(bool value) async => await _prefs?.setBool('notif_messages', value);

  // ─── Clear all ───────────────────────────────────────────────────────────
  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
