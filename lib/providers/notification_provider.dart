import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

enum NotifStatus { idle, loading, success, empty, error }

/// Responsabilidad principal:
/// Centraliza la bandeja de notificaciones globales, integrando llamadas REST (historial) y eventos Socket (en tiempo real).
///
/// Flujo dentro de la app:
/// Al iniciar sesión (ChangeNotifierProxyProvider), carga el histórico e inicia la escucha de `nueva_notificacion`. Actualiza el badge (campanita) global.
///
/// Dependencias críticas:
/// - `NotificationService` (REST).
/// - `SocketService` (Sockets).
/// - `StorageService` (Para ignorar eventos apagados en las preferencias).
///
/// Side Effects:
/// - Mutación masiva del DTO local (`NotificationModel.copyWith`) al marcar como leída para no esperar al servidor.
///
/// Recordatorios técnicos y CQRS:
/// - Sobrecarga de Red Innecesaria: Filtra notificaciones en el cliente (`_isAllowed`) según configuración local. Si un usuario desactiva notificaciones de likes, el backend las sigue emitiendo y el cliente gasta batería recibiéndolas y descartándolas. El backend debería respetar estas preferencias antes de emitir.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  final SocketService _socketService;

  NotificationProvider(this._service, this._socketService);

  String? _sessionUserId;
  bool _socketListeners = false;

  NotifStatus _status = NotifStatus.idle;
  String? _error;
  List<NotificationModel> _notifications = [];

  NotifStatus get status => _status;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;

  bool get isLoading => _status == NotifStatus.loading;
  int get unreadCount => _notifications.where((n) => !n.leida).length;

  void onAuthChanged(UserModel? user) {
    if (user == null) {
      _sessionUserId = null;
      _removeSocketListeners();
      _notifications = [];
      notifyListeners();
      return;
    }
    if (_sessionUserId == user.id) return;
    _sessionUserId = user.id;
    _ensureSocketListeners();
    loadNotifications();
  }

  void _ensureSocketListeners() {
    if (_socketListeners) return;
    _socketListeners = true;
    _socketService.on('nueva_notificacion', _handleNuevaNotificacion);
    _socketService.on('notificacion_actualizada', _handleNotificacionActualizada);
  }

  void _removeSocketListeners() {
    if (!_socketListeners) return;
    _socketService.off('nueva_notificacion');
    _socketService.off('notificacion_actualizada');
    _socketListeners = false;
  }

  void _handleNuevaNotificacion(dynamic raw) {
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    try {
      final notif = NotificationModel.fromJson(map);
      if (!_isAllowed(notif)) return;
      
      _notifications.insert(0, notif);
      if (_status == NotifStatus.empty) {
        _status = NotifStatus.success;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error parseando nueva_notificacion: $e');
    }
  }

  void _handleNotificacionActualizada(dynamic raw) {
    refresh();
  }

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
      _notifications = result.data!.where(_isAllowed).toList();
      _status = _notifications.isEmpty ? NotifStatus.empty : NotifStatus.success;
    } else {
      _status = NotifStatus.error;
      _error = result.message ?? 'Error al cargar notificaciones';
    }

    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].leida) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          usuarioId: _notifications[i].usuarioId,
          emisorId: _notifications[i].emisorId,
          emisorSnap: _notifications[i].emisorSnap,
          emisores: _notifications[i].emisores,
          totalEmisores: _notifications[i].totalEmisores,
          tipo: _notifications[i].tipo,
          publicacionId: _notifications[i].publicacionId,
          comentarioId: _notifications[i].comentarioId,
          conversacionId: _notifications[i].conversacionId,
          mensajeTexto: _notifications[i].mensajeTexto,
          leida: true,
          createdAt: _notifications[i].createdAt,
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
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
      emisorSnap: notif.emisorSnap,
      emisores: notif.emisores,
      totalEmisores: notif.totalEmisores,
      tipo: notif.tipo,
      publicacionId: notif.publicacionId,
      comentarioId: notif.comentarioId,
      conversacionId: notif.conversacionId,
      mensajeTexto: notif.mensajeTexto,
      leida: true,
      createdAt: notif.createdAt,
    );
    notifyListeners();

    // Confirmar en backend
    await _service.marcarLeida(notifId);
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────
  Future<void> refresh() => loadNotifications();
  
  // ─── Filtro de preferencias ────────────────────────────────────────────────
  bool _isAllowed(NotificationModel n) {
    if (n.tipo == 'like') return StorageService.getNotifLikes();
    if (n.tipo == 'comentario' || n.tipo == 'respuesta_comentario') return StorageService.getNotifComments();
    if (n.tipo == 'mensaje') return StorageService.getNotifMessages();
    return true;
  }
}
