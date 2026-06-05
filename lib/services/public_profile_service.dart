import 'api_service.dart';
import '../models/public_profile_model.dart';
import '../models/post_model.dart';

/// Responsabilidad principal:
/// Repositorio de dominio para consultar perfiles públicos y feeds (muros) de estudiantes de terceros.
///
/// Flujo dentro de la app:
/// Llamado por `PublicProfileProvider` y `MyProfileFeedProvider` para recuperar datos y paginar el feed del usuario.
///
/// Dependencias críticas:
/// - `ApiService` (Red).
///
/// Side Effects:
/// - Ninguno. Puramente operaciones de Lectura (Queries).
///
/// Recordatorios técnicos y CQRS:
/// - Parseo DTO: Convierte mapas JSON directamente a `PublicProfileModel` y `PostModel`. Retorna estructuras complejas (ej. el Map `{items, hasMore}`) que podrían formalizarse en un DTO Pagination.
class PublicProfileService {
  final ApiService _apiService;

  PublicProfileService(this._apiService);

  Future<ApiResult<PublicProfileModel>> getPublicProfile(String userId) async {
    final result = await _apiService.get('/perfil-publico/$userId/info');
    if (result.success && result.data != null) {
      try {
        final profile = PublicProfileModel.fromJson(result.data as Map<String, dynamic>);
        return ApiResult.ok(profile);
      } catch (e) {
        return ApiResult.error('Error al parsear perfil público: $e');
      }
    }
    return ApiResult.error(result.message ?? 'Error al obtener perfil público');
  }

  Future<ApiResult<Map<String, dynamic>>> getPublicProfileFeed(String userId, {int page = 1, int limit = 12}) async {
    final result = await _apiService.get('/perfil-publico/$userId/feed?page=$page&limit=$limit');
    if (result.success && result.data != null) {
      try {
        final dataMap = result.data as Map<String, dynamic>;
        final itemsList = dataMap['items'] as List? ?? [];
        final posts = itemsList.map((j) => PostModel.fromJson(j as Map<String, dynamic>)).toList();
        final hasMore = dataMap['hasMore'] as bool? ?? false;
        return ApiResult.ok({
          'items': posts,
          'hasMore': hasMore,
        });
      } catch (e) {
        return ApiResult.error('Error al parsear publicaciones del perfil público: $e');
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar publicaciones del perfil público');
  }

  // ─── Reportar usuario ─────────────────────────────────────────────────────
  /// POST /reportes/usuario
  /// Permite reportar a un usuario. El backend espera un motivo y un usuario destino.
  Future<ApiResult<dynamic>> reportUser({
    required String reportadoUsuarioId,
    required String tipo,
    String? descripcion,
  }) async {
    final body = {
      'reportadoUsuarioId': reportadoUsuarioId,
      'tipo': tipo,
    };
    if (descripcion != null && descripcion.isNotEmpty) {
      body['descripcion'] = descripcion;
    }
    return await _apiService.post('/reportes/usuario', body);
  }
}
