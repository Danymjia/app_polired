/// Modelo de usuario autenticado deserializado desde el backend.
class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final List<String> roles;
  final String? username;
  final String? fotoPerfil;
  /// Biografía o descripción corta del perfil (máx. 150 caracteres en backend).
  final String? biografia;
  final bool perfilCompleto;
  /// Total de publicaciones del usuario (viene de GET /perfil-estudiante).
  final int publicacionesCount;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.roles,
    this.username,
    this.fotoPerfil,
    this.biografia,
    required this.perfilCompleto,
    this.publicacionesCount = 0,
  });

  String get nombreCompleto => '$nombre $apellido';

  bool get esAdminRed => roles.contains('admin_red');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? ['estudiante'],
      username: json['username'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      biografia: json['biografia'] as String?,
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
      publicacionesCount: (json['publicacionesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'roles': roles,
        'username': username,
        'fotoPerfil': fotoPerfil,
        'biografia': biografia,
        'perfilCompleto': perfilCompleto,
      };
}
