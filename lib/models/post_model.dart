import 'dart:convert';

/// Modelo de publicación que cubre tanto publicaciones regulares como artículos.
///
/// El backend devuelve publicaciones con campos distintos según el tipo:
/// - Publicaciones: {_id, titulo, contenido, tipoContenido, categoria, mediaUrls, autorId, comunidadId, likesCount, commentsCount, timestamp }
/// - Artículos: {_id, titulo, descripcion, precio, tipoContenido, categoria, mediaUrls, autorId, redComunitaria, creadoEn }
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
  final String? descripcion;
  final String tipoContenido; // 'texto' | 'imagen'
  final String categoria; // 'comunidad' | 'noticias' | 'venta' | 'cursos'
  final List<String> mediaUrls;

  // Artículo / marketplace
  final dynamic precio;

  // Métricas
  final int likesCount;
  final int commentsCount;

  // Tiempo
  final DateTime timestamp;

  // Social
  final bool likedByMe;
  final bool savedByMe;

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
    this.descripcion,
    required this.tipoContenido,
    required this.categoria,
    required this.mediaUrls,
    this.precio,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
    this.likedByMe = false,
    this.savedByMe = false,
  });

  PostModel copyWith({
    String? id,
    String? networkId,
    String? networkName,
    String? authorId,
    String? authorUsername,
    String? authorFullName,
    String? authorImageUrl,
    String? titulo,
    String? contenido,
    String? descripcion,
    String? tipoContenido,
    String? categoria,
    List<String>? mediaUrls,
    dynamic precio,
    int? likesCount,
    int? commentsCount,
    DateTime? timestamp,
    bool? likedByMe,
    bool? savedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      networkName: networkName ?? this.networkName,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorFullName: authorFullName ?? this.authorFullName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      descripcion: descripcion ?? this.descripcion,
      tipoContenido: tipoContenido ?? this.tipoContenido,
      categoria: categoria ?? this.categoria,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      precio: precio ?? this.precio,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autorId'];
    String authorId = '';
    String authorUsername = 'Usuario';
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
          : authorFullName.isNotEmpty
          ? authorFullName
          : 'Usuario';
      authorImageUrl = autor['fotoPerfil'] as String?;
    } else if (autor is String) {
      authorId = autor;
    }

    final comunidad = json['comunidadId'] ?? json['redComunitaria'];
    String networkId = '';
    String networkName = '';
    if (comunidad is Map<String, dynamic>) {
      networkId = (comunidad['_id'] as String?) ?? '';
      networkName = (comunidad['nombre'] as String?) ?? '';
    } else if (comunidad is String) {
      networkId = comunidad;
    }

    final rawTimestamp =
        json['timestamp'] ?? json['createdAt'] ?? json['creadoEn'];
    DateTime timestamp = DateTime.now();
    if (rawTimestamp != null) {
      try {
        timestamp = DateTime.parse(rawTimestamp.toString()).toLocal();
      } catch (_) {}
    }

    final tipoContenido =
        (json['tipoContenido'] as String?)?.toLowerCase() ?? 'texto';
    final categoria = (json['categoria'] as String?)?.toLowerCase() ?? '';
    final mediaUrls = _extractMediaUrls(json['mediaUrls']);
    final contenido =
        (json['contenido'] as String?) ??
        (json['descripcion'] as String?) ??
        '';
    final descripcion = json['descripcion'] as String?;
    final precio = json['precio'];

    return PostModel(
      id: (json['_id'] as String?) ?? '',
      networkId: networkId,
      networkName: networkName,
      authorId: authorId,
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorImageUrl: authorImageUrl,
      titulo: (json['titulo'] as String?) ?? '',
      contenido: contenido,
      descripcion: descripcion,
      tipoContenido: tipoContenido,
      categoria: categoria,
      mediaUrls: mediaUrls,
      precio: precio,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      timestamp: timestamp,
      likedByMe: json['likedByMe'] ?? json['isLiked'] ?? false,
      savedByMe: json['savedByMe'] ?? json['isSaved'] ?? false,
    );
  }

  static List<String> _extractMediaUrls(dynamic raw) {
    if (raw is List) {
      return raw
          .where((item) => item is String && item.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (raw is Map) {
      return raw.values
          .where((item) => item is String && item.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (raw is String && raw.isNotEmpty) {
      final trimmed = raw.trim();
      final jsonParsed = _tryParseJsonList(trimmed);
      if (jsonParsed != null) return jsonParsed;
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }
    return [];
  }

  static List<String>? _tryParseJsonList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .where((item) => item is String && item.isNotEmpty)
            .cast<String>()
            .toList();
      }
    } catch (_) {
      // ignore invalid json
    }
    return null;
  }

  String get displayContent =>
      contenido.isNotEmpty ? contenido : descripcion ?? '';

  bool get hasImage => tipoContenido == 'imagen' && mediaUrls.isNotEmpty;

  String? get imageUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;

  String? get mediaUrl => imageUrl;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }

  bool get isArticle => categoria == 'venta' || categoria == 'cursos';

  String get priceLabel {
    if (precio == null) return '';
    if (precio is num) return '\$${precio.toString()}';
    return precio.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PostModel) return false;
    return id == other.id &&
        likedByMe == other.likedByMe &&
        savedByMe == other.savedByMe &&
        likesCount == other.likesCount &&
        commentsCount == other.commentsCount;
  }

  @override
  int get hashCode => Object.hash(id, likedByMe, savedByMe, likesCount, commentsCount);
}
