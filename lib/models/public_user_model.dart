/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable, variante ultra-ligera de perfil de usuario para listas de exploración o sugerencias.
///
/// Flujo dentro de la app:
/// Consumido masivamente por `ExploreUsersProvider` o vistas de listas (Buscador).
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Modelo puro.
///
/// Recordatorios técnicos y CQRS:
/// - DTO de lectura simple; evita sobrecarga de memoria en listas muy grandes de búsqueda.
class PublicUserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String username;
  final String? fotoPerfil;

  const PublicUserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.username,
    this.fotoPerfil,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      id: json['_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }
}
