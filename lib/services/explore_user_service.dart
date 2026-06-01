import 'api_service.dart';
import '../models/public_user_model.dart';

/// Responsabilidad principal:
/// Repositorio de dominio para obtener la lista paginada del directorio de estudiantes activos.
///
/// Flujo dentro de la app:
/// Llamado por `ExploreUsersProvider` para popular la pestaña de Búsqueda -> Personas.
///
/// Dependencias críticas:
/// - `ApiService` (Red).
///
/// Side Effects:
/// - Ninguno. Únicamente lectura.
///
/// Recordatorios técnicos y CQRS:
/// - Deuda técnica en Backend: El endpoint `/cargar/estudiantes?page=X` no acepta parámetros de búsqueda textual, forzando a la app a buscar solo entre los que ya descargó. Esto corrompe la experiencia UX de búsqueda.
class ExploreUserService {
  final ApiService _apiService;

  ExploreUserService(this._apiService);

  Future<ApiResult<Map<String, dynamic>>> getUsers({int page = 1, int limit = 10}) async {
    final result = await _apiService.get('/cargar/estudiantes?page=$page&limit=$limit');
    if (result.success && result.data != null) {
      try {
        final dataMap = result.data as Map<String, dynamic>;
        final itemsList = dataMap['items'] as List? ?? [];
        final list = itemsList
            .map((item) => PublicUserModel.fromJson(item as Map<String, dynamic>))
            .toList();
        final hasMore = dataMap['hasMore'] as bool? ?? false;
        return ApiResult.ok({
          'items': list,
          'hasMore': hasMore,
        });
      } catch (e) {
        return ApiResult.error('Error al parsear listado de estudiantes: $e');
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar estudiantes');
  }
}
