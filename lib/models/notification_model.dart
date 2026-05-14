/// Modelo de notificación mapeado desde el backend.
///
/// El backend devuelve (GET /notificaciones):
/// {
///   notificaciones: [
///     { _id, usuarioId, emisorId, tipo, publicacionId, comentarioId,
///       conversacionId, mensaje, leida, createdAt, updatedAt }
///   ]
/// }
///
/// Tipos soportados: 'like' | 'comentario' | 'respuesta_comentario' | 'mensaje'
class NotificationModel {
  final String id;
  final String usuarioId;
  final String? emisorId;
  final String tipo;
  final String? publicacionId;
  final String? comentarioId;
  final String? conversacionId;
  final String? mensaje;
  final bool leida;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.usuarioId,
    this.emisorId,
    required this.tipo,
    this.publicacionId,
    this.comentarioId,
    this.conversacionId,
    this.mensaje,
    required this.leida,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime ts = DateTime.now();
    final rawTs = json['createdAt'];
    if (rawTs != null) {
      try {
        ts = DateTime.parse(rawTs.toString()).toLocal();
      } catch (_) {}
    }

    return NotificationModel(
      id: (json['_id'] as String?) ?? '',
      usuarioId: json['usuarioId'] is String
          ? json['usuarioId'] as String
          : (json['usuarioId']?['_id'] as String?) ?? '',
      emisorId: json['emisorId'] is String
          ? json['emisorId'] as String?
          : (json['emisorId']?['_id'] as String?),
      tipo: (json['tipo'] as String?) ?? 'mensaje',
      publicacionId: json['publicacionId'] is String
          ? json['publicacionId'] as String?
          : (json['publicacionId']?['_id'] as String?),
      comentarioId: json['comentarioId'] is String
          ? json['comentarioId'] as String?
          : (json['comentarioId']?['_id'] as String?),
      conversacionId: json['conversacionId'] is String
          ? json['conversacionId'] as String?
          : (json['conversacionId']?['_id'] as String?),
      mensaje: json['mensaje'] as String?,
      leida: (json['leida'] as bool?) ?? false,
      createdAt: ts,
    );
  }

  /// Icono representativo según tipo
  String get icon {
    switch (tipo) {
      case 'like':
        return '❤️';
      case 'comentario':
        return '💬';
      case 'respuesta_comentario':
        return '↩️';
      case 'mensaje':
        return '📢';
      default:
        return '🔔';
    }
  }

  /// Etiqueta de tipo legible
  String get tipoLabel {
    switch (tipo) {
      case 'like':
        return 'Me gusta';
      case 'comentario':
        return 'Comentario';
      case 'respuesta_comentario':
        return 'Respuesta';
      case 'mensaje':
        return 'Mensaje';
      default:
        return 'Notificación';
    }
  }

  /// Tiempo relativo
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }

  /// Determina el grupo temporal para agrupar en la UI
  NotificationGroup get group {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inHours < 24) return NotificationGroup.today;
    if (diff.inDays < 7) return NotificationGroup.thisWeek;
    return NotificationGroup.earlier;
  }
}

enum NotificationGroup { today, thisWeek, earlier }

extension NotificationGroupLabel on NotificationGroup {
  String get label {
    switch (this) {
      case NotificationGroup.today:
        return 'Hoy';
      case NotificationGroup.thisWeek:
        return 'Esta semana';
      case NotificationGroup.earlier:
        return 'Anteriormente';
    }
  }
}
