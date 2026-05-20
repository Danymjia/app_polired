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
