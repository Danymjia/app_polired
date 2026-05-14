import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

enum NotifStatus { idle, loading, success, empty, error }

/// Provider de notificaciones.
/// Consume GET /notificaciones y PATCH /notificaciones/:id/leida.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  NotifStatus _status = NotifStatus.idle;
  String? _error;
  List<NotificationModel> _notifications = [];

  NotifStatus get status => _status;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;

  bool get isLoading => _status == NotifStatus.loading;
  int get unreadCount => _notifications.where((n) => !n.leida).length;

  /// Notificaciones agrupadas por tiempo: Hoy / Esta semana / Anteriormente
  Map<NotificationGroup, List<NotificationModel>> get grouped {
    final map = <NotificationGroup, List<NotificationModel>>{};
    for (final n in _notifications) {
      map.putIfAbsent(n.group, () => []).add(n);
    }
    return map;
  }

  // ─── Cargar notificaciones ─────────────────────────────────────────────────
  Future<void> loadNotifications() async {
    _status = NotifStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _service.getNotificaciones();

    if (result.success && result.data != null) {
      _notifications = result.data!;
      _status = _notifications.isEmpty ? NotifStatus.empty : NotifStatus.success;
    } else {
      _status = NotifStatus.error;
      _error = result.message ?? 'Error al cargar notificaciones';
    }

    notifyListeners();
  }

  // ─── Marcar como leída ────────────────────────────────────────────────────
  Future<void> markAsRead(String notifId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx == -1) return;

    // Optimistic update
    final notif = _notifications[idx];
    if (notif.leida) return;

    _notifications[idx] = NotificationModel(
      id: notif.id,
      usuarioId: notif.usuarioId,
      emisorId: notif.emisorId,
      tipo: notif.tipo,
      publicacionId: notif.publicacionId,
      comentarioId: notif.comentarioId,
      conversacionId: notif.conversacionId,
      mensaje: notif.mensaje,
      leida: true,
      createdAt: notif.createdAt,
    );
    notifyListeners();

    // Confirmar en backend
    await _service.marcarLeida(notifId);
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────
  Future<void> refresh() => loadNotifications();
}
