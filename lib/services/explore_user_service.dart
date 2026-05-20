import 'api_service.dart';
import '../models/public_user_model.dart';

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
