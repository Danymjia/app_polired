import '../config/constants.dart';
import 'api_service.dart';

class NetworkService {
  final ApiService _api;

  NetworkService(this._api);

  Future<ApiResult<List<dynamic>>> getRedes() async {
    final result = await _api.get(AppConstants.redesListarEndpoint);
    
    if (result.success && result.data is List) {
      return ApiResult.ok(result.data as List<dynamic>);
    }
    
    return ApiResult.error(result.message ?? 'Error al obtener redes comunitarias');
  }

  Future<ApiResult<dynamic>> unirseRed(String redId) async {
    final result = await _api.post(AppConstants.unirseRedEndpoint, {
      'redId': redId,
    });
    
    if (result.success) {
      return ApiResult.ok(result.data);
    }
    
    return ApiResult.error(result.message ?? 'Error al unirse a la red');
  }
}
