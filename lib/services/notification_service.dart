import 'api_service.dart';
import '../models/notification_model.dart';
import '../config/constants.dart';

/// Responsabilidad principal:
/// Repositorio de dominio para la carga inicial y el marcado de lectura del historial de Notificaciones.
///
/// Flujo dentro de la app:
/// Llamado exclusivamente por el `NotificationProvider` para traer el historial REST y sincronizar estados de lectura (`leida: true`).
///
/// Dependencias críticas:
/// - `ApiService` (Cliente HTTP).
///
/// Side Effects:
/// - Envía Commands (`marcarLeida`) que alteran el registro de la base de datos central.
///
/// Recordatorios técnicos y CQRS:
/// - Responsabilidad acotada: A diferencia de `PostService`, este archivo mantiene un SRP claro y delegado (Query vs Command simples).
class NotificationService {
  final ApiService _api;

  NotificationService(this._api);

  // ─── Listar notificaciones ─────────────────────────────────────────────────
  /// GET /notificaciones
  /// Respuesta: { notificaciones: [ <Notificacion> ] }
  Future<ApiResult<List<NotificationModel>>> getNotificaciones() async {
    final result = await _api.get(AppConstants.notificacionesEndpoint);

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
    return _api.patch('${AppConstants.notificacionesEndpoint}/$notifId/leida', {});
  }
}
