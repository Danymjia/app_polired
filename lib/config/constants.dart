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

  // ─── Base endpoints ────────────────────────────────────────────────────────
  static const String estudianteBaseEndpoint = '/estudiante';
  static const String estudiantesBaseEndpoint = '/estudiantes';
  static const String adminRedBaseEndpoint = '/admin-red';

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
  static const String redesEndpoint = '/redes';
  static const String redesListarEndpoint = '/redes/listar';
  static const String unirseRedEndpoint = '/estudiantes/unirse/red';
  static const String redesEstudianteEndpoint = '/estudiantes/listar/redes';
  static const String redesSolicitarCreacionEndpoint =
      '/redes/solicitar-creacion';
  static const String redesSolicitarVerificacionEndpoint =
      '/redes/solicitar-verificacion';
  static const String redesSolicitarOficializacionEndpoint =
      '/redes/solicitar-oficializacion';
  static const String salirseRedEndpoint = '/salirse/red';

  // ─── Exploración y Usuarios endpoints ───────────────────────────────────────
  static const String cargarEstudiantesEndpoint = '/cargar/estudiantes';
  static const String perfilPublicoEndpoint = '/perfil-publico';

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

  /// Publicaciones de artículos
  static const String publicacionesArticulosEndpoint =
      '/publicaciones/articulos';

  // ─── Social endpoints ────────────────────────────────────────────────────────

  // DEUDA TÉCNICA (pendiente de renombrar):
  // `likeEndpoint` y `comentariosEndpoint` son nombres engañosos. Ambas
  // constantes apuntan a '/publicaciones' porque funcionan como prefijo base
  // para construir rutas dinámicas (ej. '$comentariosEndpoint/$id/comentarios').
  // El nombre correcto sería `publicacionesBaseEndpoint`. Se mantienen con sus
  // nombres originales para no romper los servicios que ya dependen de ellas,
  // pero deben renombrarse en una refactorización futura dedicada.
  // Ver: informe_tecnico_polired.md → sección Deuda Técnica.

  /// Base para rutas de publicaciones → /publicaciones/:id/like
  static const String likeEndpoint = '/publicaciones';

  /// Base para rutas de comentarios → /publicaciones/:id/comentarios
  static const String comentariosEndpoint = '/publicaciones';

  /// Respuestas a comentarios
  static const String respuestasComentarioEndpoint = '/comentarios';

  /// Guardados y Likes de usuario
  static const String usuariosGuardadosEndpoint = '/usuarios/guardados';
  static const String usuariosLikesEndpoint = '/usuarios/likes';

  // ─── Reportes endpoints ──────────────────────────────────────────────────────
  static const String reportesUsuarioEndpoint = '/reportes/usuario';
  static const String reportesRedEndpoint = '/reportes/red';
  static const String reportesPublicacionEndpoint = '/reportes/publicacion';
  static const String reportesArticuloEndpoint = '/reportes/articulo';
  static const String reportesAppEndpoint = '/reportes/app';

  // ─── Notificaciones endpoints ────────────────────────────────────────────────
  /// Listar notificaciones del usuario → GET /notificaciones (requiere auth)
  static const String notificacionesEndpoint = '/notificaciones';

  /// Marcar notificación como leída → PATCH /notificaciones/:id/leida (requiere auth)
  static const String marcarLeidaEndpoint = '/notificaciones';

  // ─── Mensajes / conversaciones ───────────────────────────────────────────────
  /// Listar conversaciones del usuario → GET /mensajes/conversaciones (requiere auth)
  static const String mensajesConversacionesEndpoint =
      '/mensajes/conversaciones';
  static const String conversacionesEndpoint = '/conversaciones';
  static const String mensajesEntreEndpoint = '/entre';
  static const String conversacionEndpoint = '/conversacion';
  static const String enviarMensajeEndpoint = '/send';

  // ─── Storage keys ────────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // ─── Misc ─────────────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 30);
  static const String kApelacionUrl =
      'https://polired.vercel.app/crearApelacion';
  static const String kGestionRedUrl = 'https://polired.vercel.app/login';
}
