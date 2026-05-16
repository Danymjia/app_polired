import '../utils/json_ids.dart';

/// Participante contrario en un chat 1:1.
class ChatPeerModel {
  final String id;
  final String nombre;
  final String apellido;
  final String? username;
  final String? fotoPerfil;

  const ChatPeerModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.username,
    this.fotoPerfil,
  });

  String get displayName {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return '$nombre $apellido'.trim();
  }

  factory ChatPeerModel.fromJson(Map<String, dynamic> json) {
    return ChatPeerModel(
      id: parseMongoId(json['_id']) ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      username: json['username'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }
}

/// Metadatos del último mensaje en la conversación (HTTP o actualización local).
class UltimoMensajeModel {
  final String? contenido;
  final String? autorId;
  final DateTime? fecha;

  const UltimoMensajeModel({
    this.contenido,
    this.autorId,
    this.fecha,
  });

  factory UltimoMensajeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UltimoMensajeModel();
    return UltimoMensajeModel(
      contenido: json['contenido'] as String?,
      autorId: parseMongoId(json['autorId']),
      fecha: parseDate(json['fecha']),
    );
  }

  UltimoMensajeModel copyWith({
    String? contenido,
    String? autorId,
    DateTime? fecha,
  }) {
    return UltimoMensajeModel(
      contenido: contenido ?? this.contenido,
      autorId: autorId ?? this.autorId,
      fecha: fecha ?? this.fecha,
    );
  }
}

/// Conversación 1:1 tal como la devuelve GET /mensajes/conversaciones.
class ConversationModel {
  final String id;
  final ChatPeerModel? peer;
  final UltimoMensajeModel? ultimoMensaje;
  final DateTime ultimaActividad;

  const ConversationModel({
    required this.id,
    this.peer,
    this.ultimoMensaje,
    required this.ultimaActividad,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participante = json['participante'];
    ChatPeerModel? peer;
    if (participante is Map<String, dynamic>) {
      peer = ChatPeerModel.fromJson(participante);
    }
    final um = json['ultimoMensaje'];
    return ConversationModel(
      id: parseMongoId(json['id'] ?? json['_id']) ?? '',
      peer: peer,
      ultimoMensaje: um is Map<String, dynamic> ? UltimoMensajeModel.fromJson(um) : null,
      ultimaActividad: parseDate(json['ultimaActividad']) ?? DateTime.now(),
    );
  }

  ConversationModel copyWith({
    UltimoMensajeModel? ultimoMensaje,
    DateTime? ultimaActividad,
  }) {
    return ConversationModel(
      id: id,
      peer: peer,
      ultimoMensaje: ultimoMensaje ?? this.ultimoMensaje,
      ultimaActividad: ultimaActividad ?? this.ultimaActividad,
    );
  }
}
