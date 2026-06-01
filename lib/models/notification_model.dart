/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable para representar notificaciones del sistema agrupadas por emisor.
///
/// Flujo dentro de la app:
/// Parseado por `NotificationService` y listado en el `NotificationProvider` para su consumo en la UI.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Modelo puramente de lectura (DTO).
///
/// Recordatorios técnicos y CQRS:
/// - El backend agrupa múltiples emisores (agregación) en una misma notificación (ej. "3 personas le dieron like").
/// - La lógica de presentación de texto de la UI (ej. "y 2 más le dieron like") se resuelve en el getter de dominio `textoResumido`.
class EmisorSnap {
  final String nombre;
  final String apellido;
  final String username;
  final String? fotoPerfil;

  EmisorSnap.fromJson(Map<String, dynamic> json)
      : nombre = json['nombre'] ?? '',
        apellido = json['apellido'] ?? '',
        username = json['username'] ?? '',
        fotoPerfil = json['fotoPerfil'];

  String get nombreCompleto => '$nombre $apellido'.trim();
}
class NotificationModel {
  final String id;
  final String usuarioId;
  final String? emisorId;
  final EmisorSnap? emisorSnap;
  final List<EmisorSnap> emisores;
  final int totalEmisores;
  final String tipo;
  final String? publicacionId;
  final String? comentarioId;
  final String? conversacionId;
  final String? mensajeTexto;
  final bool leida;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.usuarioId,
    this.emisorId,
    this.emisorSnap,
    this.emisores = const [],
    this.totalEmisores = 1,
    required this.tipo,
    this.publicacionId,
    this.comentarioId,
    this.conversacionId,
    this.mensajeTexto,
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
      emisorSnap: json['emisorSnap'] != null
          ? EmisorSnap.fromJson(json['emisorSnap'])
          : (json['emisorId'] is Map<String, dynamic> ? EmisorSnap.fromJson(json['emisorId']) : null),
      emisores: (json['emisores'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => EmisorSnap.fromJson(e))
          .toList(),
      totalEmisores: (json['totalEmisores'] as num?)?.toInt() ?? 1,
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
      mensajeTexto: json['mensaje'],
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

  String get textoResumido {
    final primerNombre = emisorSnap?.nombre ?? (emisores.isNotEmpty ? emisores.first.nombre : 'Alguien');
    switch (tipo) {
      case 'like':
        if (totalEmisores <= 1) return '$primerNombre le dio like a tu publicación';
        if (totalEmisores == 2) {
          final segundo = emisores.length > 1 ? emisores[1].nombre : 'alguien más';
          return '$primerNombre y $segundo le dieron like a tu publicación';
        }
        return '$primerNombre y ${totalEmisores - 1} más le dieron like a tu publicación';
      case 'comentario':
        return '$primerNombre comentó tu publicación';
      case 'respuesta_comentario':
        return '$primerNombre respondió a tu comentario';
      case 'mensaje':
        return mensajeTexto ?? 'Nueva notificación del sistema';
      default:
        return 'Nueva notificación';
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
