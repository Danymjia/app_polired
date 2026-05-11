/// Modelo de usuario autenticado deserializado desde el backend.
class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final List<String> roles;
  final String? username;
  final String? fotoPerfil;
  final bool perfilCompleto;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.roles,
    this.username,
    this.fotoPerfil,
    required this.perfilCompleto,
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
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
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
        'perfilCompleto': perfilCompleto,
      };
}
