import 'api_service.dart';
import '../models/notification_model.dart';

/// Servicio de notificaciones del backend.
/// Endpoints utilizados:
///   - GET   /notificaciones            → listar notificaciones del usuario autenticado
///   - PATCH /notificaciones/:id/leida  → marcar notificación como leída
class NotificationService {
  final ApiService _api;

  NotificationService(this._api);

  // ─── Listar notificaciones ─────────────────────────────────────────────────
  /// GET /notificaciones
  /// Respuesta: { notificaciones: [ <Notificacion> ] }
  Future<ApiResult<List<NotificationModel>>> getNotificaciones() async {
    final result = await _api.get('/notificaciones');

    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final rawList = data['notificaciones'];
      if (rawList is List) {
        final notifs = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => NotificationModel.fromJson(j))
            .toList();
        return ApiResult.ok(notifs);
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar notificaciones');
  }

  // ─── Marcar notificación como leída ───────────────────────────────────────
  /// PATCH /notificaciones/:id/leida
  /// Respuesta: { msg: 'Notificación marcada como leída' }
  Future<ApiResult<dynamic>> marcarLeida(String notifId) async {
    return _api.patch('/notificaciones/$notifId/leida', {});
  }
}
