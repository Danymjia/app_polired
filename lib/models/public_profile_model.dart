/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable para representar el perfil público de otro usuario (incluyendo sus estadísticas y redes asociadas).
///
/// Flujo dentro de la app:
/// Parseado tras consultar la API de perfiles públicos, consumido centralizadamente por el `PublicProfileProvider`.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Modelo puramente de lectura (Query Side).
///
/// Recordatorios técnicos y CQRS:
/// - La lista `redes` contiene objetos de tipo `PublicProfileNetworkModel` que son DTOs anidados.
class PublicProfileModel {
  final String id;
  final String nombre;
  final String apellido;
  final String username;
  final String? fotoPerfil;
  final String? biografia;
  final List<PublicProfileNetworkModel> redes;
  final int publicacionesCount;
  final int redesCount;

  const PublicProfileModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.username,
    this.fotoPerfil,
    this.biografia,
    required this.redes,
    required this.publicacionesCount,
    required this.redesCount,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final redesList = (json['redComunitaria'] as List<dynamic>?)
            ?.map((e) => PublicProfileNetworkModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PublicProfileModel(
      id: json['_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fotoPerfil: json['fotoPerfil'] as String?,
      biografia: json['biografia'] as String?,
      redes: redesList,
      publicacionesCount: (stats['publicacionesCount'] as num?)?.toInt() ?? 0,
      redesCount: (stats['redesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PublicProfileNetworkModel {
  final String id;
  final String nombre;
  final String? fotoPerfil;
  final String acronym;

  const PublicProfileNetworkModel({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    required this.acronym,
  });

  factory PublicProfileNetworkModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileNetworkModel(
      id: json['_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      fotoPerfil: json['fotoPerfil'] as String?,
      acronym: json['acronym'] as String? ?? '',
    );
  }
}
