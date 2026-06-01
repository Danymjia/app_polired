/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable que representa un mensaje individual dentro de un chat.
///
/// Flujo dentro de la app:
/// Instanciado a través de respuestas HTTP (paginación en `ChatScreen`) o eventos de Socket en tiempo real vía `SocketService`.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Modelo puramente de lectura.
///
/// Recordatorios técnicos y CQRS:
/// - Las referencias `autor` y `destinatario` llegan como Strings planas o como Objetos (Map) dependiendo del evento o query que lo emita (inconsistencia del Backend mitigada en `fromJson`).
class MessageModel {
  final String id;
  final String conversacionId;
  final String autorId;
  final String destinatarioId;
  final String contenido;
  final bool leido;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversacionId,
    required this.autorId,
    required this.destinatarioId,
    required this.contenido,
    required this.leido,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt']).toLocal();
      } catch (_) {}
    }
    
    // Parse autor and destinatario which could be objects or strings
    String aId = '';
    if (json['autor'] is Map) {
      aId = json['autor']['_id'] ?? '';
    } else {
      aId = json['autor'] ?? '';
    }

    String dId = '';
    if (json['destinatario'] is Map) {
      dId = json['destinatario']['_id'] ?? '';
    } else {
      dId = json['destinatario'] ?? '';
    }

    return MessageModel(
      id: json['_id'] ?? '',
      conversacionId: json['conversacionId'] ?? '',
      autorId: aId,
      destinatarioId: dId,
      contenido: json['contenido'] ?? '',
      leido: json['leido'] ?? false,
      createdAt: parsedDate,
    );
  }

  MessageModel copyWith({
    String? id,
    String? conversacionId,
    String? autorId,
    String? destinatarioId,
    String? contenido,
    bool? leido,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversacionId: conversacionId ?? this.conversacionId,
      autorId: autorId ?? this.autorId,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      contenido: contenido ?? this.contenido,
      leido: leido ?? this.leido,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
