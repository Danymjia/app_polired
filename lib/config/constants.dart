/// Constantes globales de la aplicación Polired.
class AppConstants {
  AppConstants._();

  // ─── Backend ───────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String socketUrl = 'http://10.0.2.2:3000';

  // ─── Auth endpoints ────────────────────────────────────────────────────────
  static const String loginEndpoint = '/auth/login';
  static const String registroEndpoint = '/registro-estudiantes';
  static const String recuperarPasswordEndpoint = '/recuperar-password-e';
  static const String perfilEndpoint = '/perfil-estudiante';

  // ─── Storage keys ──────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // ─── Misc ──────────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);
}
