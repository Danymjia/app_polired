import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

/// Gestión de persistencia local con SharedPreferences.
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

  // ─── Clear all ───────────────────────────────────────────────────────────
  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
