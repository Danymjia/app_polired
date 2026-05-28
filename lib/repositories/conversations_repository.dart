import '../models/conversation_model.dart';
import '../services/api_service.dart';

/// Acceso HTTP a conversaciones 1:1 (sin modificar contratos del backend).
class ConversationsRepository {
  final ApiService _api;

  ConversationsRepository(this._api);

  /// GET /conversaciones → { conversaciones: [...] }
  Future<ApiResult<List<ConversationModel>>> fetchConversations() async {
    final result = await _api.get('/conversaciones');
    if (!result.success) {
      return ApiResult.error(result.message ?? 'Error al cargar conversaciones', statusCode: result.statusCode);
    }
    final data = result.data;
    if (data is! Map) {
      return ApiResult.error('Respuesta inválida del servidor');
    }
    final raw = data['conversaciones'];
    if (raw is! List) {
      return ApiResult.error('Respuesta inválida del servidor');
    }
    final list = raw
        .whereType<Map>()
        .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id.isNotEmpty)
        .toList();
    return ApiResult.ok(list, statusCode: result.statusCode);
  }

  /// GET /entre/:otherId → { conversacion: { _id: ... }, mensajes: [...] }
  Future<ApiResult<String>> getOrCreateConversation(String contactId) async {
    final result = await _api.get('/entre/$contactId');
    if (!result.success) {
      return ApiResult.error(result.message ?? 'Error al iniciar conversación', statusCode: result.statusCode);
    }
    
    final data = result.data;
    if (data is! Map) {
      return ApiResult.error('Respuesta inválida del servidor');
    }
    
    final conversacion = data['conversacion'];
    if (conversacion is! Map || conversacion['_id'] == null) {
      return ApiResult.error('Respuesta inválida del servidor: _id no encontrado');
    }
    
    final id = conversacion['_id'].toString();
    return ApiResult.ok(id, statusCode: result.statusCode);
  }
}
