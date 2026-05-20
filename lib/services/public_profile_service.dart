import 'api_service.dart';
import '../models/public_profile_model.dart';
import '../models/post_model.dart';

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
}
