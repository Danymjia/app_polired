import 'dart:convert';

/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable de dominio que agrupa propiedades de Publicaciones Regulares y Artículos/Marketplace.
///
/// Flujo dentro de la app:
/// Instanciado masivamente vía `fromJson`. Es la única fuente de verdad para las vistas de contenido y se cachea centralizadamente en `PostStoreProvider`.
///
/// Dependencias críticas:
/// - `dart:convert` (para corregir estructuras mal formadas en URLs de medios).
///
/// Side Effects:
/// - Ninguno. Modelo puramente de lectura (DTO).
///
/// Recordatorios técnicos y CQRS:
/// - Deuda Técnica de Dominio: Agrupa propiedades de "Posts" y "Artículos" en un solo DTO híbrido (`precio`, `hasImage`, `isArticle`). 
///   Sería arquitectónicamente superior usar Herencia (PostBase, TextPost, MarketplacePost).
/// - Implementa `operator ==` y `hashCode` usando métricas de interacciones (likes, comentarios) para forzar reconstrucciones precisas del UI.
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
  final double aspectRatio;

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
    this.aspectRatio = 1.0,
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
    double? aspectRatio,
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
      aspectRatio: aspectRatio ?? this.aspectRatio,
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

    final comunidad = json['comunidadId'] ?? json['redComunitaria'] ?? json['comunidad'];
    String networkId = '';
    String networkName = '';
    if (comunidad is Map<String, dynamic>) {
      networkId = (comunidad['_id']?.toString()) ?? '';
      networkName = (comunidad['nombre']?.toString()) ?? '';
    } else if (comunidad is String) {
      networkId = comunidad;
    }

    final rawTimestamp =
        json['timestamp'] ?? json['createdAt'] ?? json['creadoEn'] ?? json['fechaCreacion'];
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

    final rawId = (json['_id'] as String?) ?? '';
    final isArticle = categoria == 'venta' || categoria == 'cursos';
    final idWithPrefix = rawId.isNotEmpty
        ? (isArticle ? 'articulo:$rawId' : 'publicacion:$rawId')
        : '';

    return PostModel(
      id: idWithPrefix,
      networkId: networkId,
      networkName: networkName,
      authorId: authorId,
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorImageUrl: authorImageUrl,
      titulo: (json['titulo']?.toString()) ?? '',
      contenido: contenido,
      descripcion: descripcion,
      tipoContenido: tipoContenido,
      categoria: categoria,
      mediaUrls: mediaUrls,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      precio: precio,
      likesCount: _parseInt(json['likesCount'] ?? json['likes'] ?? 0),
      commentsCount: _parseInt(json['commentsCount'] ?? json['comentarios'] ?? 0),
      timestamp: timestamp,
      likedByMe: _parseBool(json['likedByMe'] ?? json['isLiked'] ?? false),
      savedByMe: _parseBool(json['savedByMe'] ?? json['isSaved'] ?? false),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value > 0;
    return false;
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
    if (precio is num) {
      if (precio == 0 || precio == 0.0) return 'Gratis';
      return '\$${precio.toString()}';
    }
    final pStr = precio.toString();
    if (pStr == '0' || pStr == '0.0' || pStr == '0.00') return 'Gratis';
    return pStr;
  }

  bool get liked => likedByMe;
  bool get saved => savedByMe;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PostModel) return false;
    return id == other.id &&
        likedByMe == other.likedByMe &&
        savedByMe == other.savedByMe &&
        likesCount == other.likesCount &&
        commentsCount == other.commentsCount &&
        aspectRatio == other.aspectRatio;
  }

  @override
  int get hashCode => Object.hash(id, likedByMe, savedByMe, likesCount, commentsCount, aspectRatio);
}
