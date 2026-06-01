/// Responsabilidad principal:
/// Almacena constantes globales de la aplicación, principalmente rutas de la API, websockets y claves de almacenamiento.
///
/// Flujo dentro de la app:
/// Consumido transversalmente por `ApiService`, `SocketService`, y `StorageService` para resolver endpoints y claves.
///
/// Dependencias críticas:
/// - Ninguna (puro Dart).
///
/// Side Effects:
/// - Ninguno. Define valores estáticos de solo lectura en memoria.
///
/// Recordatorios técnicos y CQRS:
/// - No contiene estado.
/// - Riesgo de acoplamiento: Las URLs apuntan directo a Vercel. Si hay ambientes dev/prod, migrar URLs base al `.env`.
class AppConstants {
  AppConstants._();

  // ─── Backend ────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://polired-api.vercel.app/api';
  static const String socketUrl = 'https://polired-api.vercel.app';

  // ─── Auth endpoints ─────────────────────────────────────────────────────────
  static const String loginEndpoint = '/auth/login';
  static const String registroEndpoint = '/registro-estudiantes';
  static const String recuperarPasswordEndpoint = '/recuperar-password-e';
  static const String perfilEndpoint = '/perfil-estudiante';
  static const String perfilUsernameEndpoint = '/perfil/username';
  static const String completarPerfilEndpoint = '/completar/perfil';
  static const String actualizarPasswordEndpoint =
      '/estudiante/actualizarpassword';

  // ─── Redes endpoints ────────────────────────────────────────────────────────
  static const String redesListarEndpoint = '/redes/listar';
  static const String unirseRedEndpoint = '/estudiantes/unirse/red';
  static const String redesEstudianteEndpoint = '/estudiantes/listar/redes';

  // ─── Publicaciones endpoints ─────────────────────────────────────────────────
  /// Feed global paginado (sin auth requerida)
  static const String publicacionesGlobalEndpoint = '/publicaciones/global';

  /// Feed de comunidades paginado (sin auth requerida)
  static const String publicacionesComunidadesEndpoint =
      '/publicaciones/comunitarias';

  /// Feed filtrado por red → /publicaciones/red/:redId  (requiere auth)
  static const String publicacionesPorRedEndpoint = '/publicaciones/red';

  /// Crear publicación simple → POST /estudiantes/publicaciones (requiere auth + perfil completo)
  static const String crearPublicacionEndpoint = '/estudiantes/publicaciones';

  /// Crear publicación extendida → POST /publicaciones/extendida (requiere auth + perfil completo)
  static const String crearPublicacionExtendidaEndpoint =
      '/publicaciones/extendida';

  // ─── Social endpoints ────────────────────────────────────────────────────────
  /// Like → POST /publicaciones/:id/like
  static const String likeEndpoint = '/publicaciones';

  /// Comentarios → POST /publicaciones/:id/comentarios
  static const String comentariosEndpoint = '/publicaciones';

  // ─── Notificaciones endpoints ────────────────────────────────────────────────
  /// Listar notificaciones del usuario → GET /notificaciones (requiere auth)
  static const String notificacionesEndpoint = '/notificaciones';

  /// Marcar notificación como leída → PATCH /notificaciones/:id/leida (requiere auth)
  static const String marcarLeidaEndpoint = '/notificaciones';

  // ─── Mensajes / conversaciones ───────────────────────────────────────────────
  /// Listar conversaciones del usuario → GET /mensajes/conversaciones (requiere auth)
  static const String mensajesConversacionesEndpoint =
      '/mensajes/conversaciones';

  // ─── Storage keys ────────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // ─── Misc ─────────────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);
}
