import '../models/conversation_model.dart';
import '../services/api_service.dart';

/// Responsabilidad principal:
/// Repositorio de datos estricto para extraer las conversaciones 1:1 desde la API y mapearlas a Objetos de Dominio (`ConversationModel`).
///
/// Flujo dentro de la app:
/// Actúa como capa de abstracción para `MessagesInboxProvider`. Realiza la llamada HTTP y parsea defensivamente los JSON asumiendo que el backend puede omitir campos.
///
/// Dependencias críticas:
/// - `ApiService` (Red).
///
/// Side Effects:
/// - Ninguno. Puramente de lectura (Data Fetching / Mapping).
///
/// Recordatorios técnicos y CQRS:
/// - Diseño Correcto: A diferencia de la carpeta `/services` (que actúa como Repositorio y Cliente REST a la vez), este archivo cumple correctamente el patrón Repository al aislar el conocimiento del JSON de los Providers.
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
