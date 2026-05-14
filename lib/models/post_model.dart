/// Modelo de publicación mapeado desde la respuesta real del backend.
///
/// El backend devuelve (en /publicaciones/global):
/// {
///   _id, titulo, contenido, tipoContenido, categoria, mediaUrl,
///   autorId: { _id, nombre, apellido, username },
///   comunidadId: { _id, nombre },
///   likesCount, commentsCount, timestamp, createdAt
/// }
class PostModel {
  final String id;
  final String networkId;
  final String networkName;

  // Autor
  final String authorId;
  final String authorUsername;
  final String authorFullName;
  final String? authorImageUrl;

  // Contenido
  final String titulo;
  final String contenido;
  final String tipoContenido; // 'texto' | 'imagen' | 'video'
  final String? mediaUrl;

  // Métricas
  final int likesCount;
  final int commentsCount;

  // Tiempo
  final DateTime timestamp;

  const PostModel({
    required this.id,
    required this.networkId,
    required this.networkName,
    required this.authorId,
    required this.authorUsername,
    required this.authorFullName,
    this.authorImageUrl,
    required this.titulo,
    required this.contenido,
    required this.tipoContenido,
    this.mediaUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Autor puede venir poblado o como ID simple
    final autor = json['autorId'];
    String authorId = '';
    String authorUsername = 'usuario';
    String authorFullName = '';
    String? authorImageUrl;

    if (autor is Map<String, dynamic>) {
      authorId = (autor['_id'] as String?) ?? '';
      final username = autor['username'] as String?;
      final nombre = autor['nombre'] as String? ?? '';
      final apellido = autor['apellido'] as String? ?? '';
      authorFullName = '$nombre $apellido'.trim();
      authorUsername = (username != null && username.isNotEmpty)
          ? username
          : authorFullName;
      authorImageUrl = autor['fotoPerfil'] as String?;
    } else if (autor is String) {
      authorId = autor;
    }

    // Red
    final comunidad = json['comunidadId'];
    String networkId = '';
    String networkName = '';
    if (comunidad is Map<String, dynamic>) {
      networkId = (comunidad['_id'] as String?) ?? '';
      networkName = (comunidad['nombre'] as String?) ?? '';
    } else if (comunidad is String) {
      networkId = comunidad;
    }

    // Timestamp
    DateTime ts = DateTime.now();
    final rawTs = json['timestamp'] ?? json['createdAt'];
    if (rawTs != null) {
      try {
        ts = DateTime.parse(rawTs.toString()).toLocal();
      } catch (_) {}
    }

    return PostModel(
      id: (json['_id'] as String?) ?? '',
      networkId: networkId,
      networkName: networkName,
      authorId: authorId,
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorImageUrl: authorImageUrl,
      titulo: (json['titulo'] as String?) ?? '',
      contenido: (json['contenido'] as String?) ?? '',
      tipoContenido: (json['tipoContenido'] as String?) ?? 'texto',
      mediaUrl: json['mediaUrl'] as String?,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      timestamp: ts,
    );
  }

  /// Devuelve el tiempo relativo de la publicación (ej. "Hace 2 h")
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }

  bool get hasImage => tipoContenido == 'imagen' && mediaUrl != null && mediaUrl!.isNotEmpty;
}
