import '../utils/json_ids.dart';

/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable para la vista detallada del perfil de una Red o Comunidad.
///
/// Flujo dentro de la app:
/// Parseado por `NetworkProfileProvider` tras ejecutar la Query `/redes/:id`.
///
/// Dependencias críticas:
/// - `json_ids.dart` (parseo seguro frente a `$oid`).
///
/// Side Effects:
/// - Ninguno. Modelo puro.
///
/// Recordatorios técnicos y CQRS:
/// - DTO estrictamente de lectura. Cualquier mutación (ej. unirse a la red) se dispara como un Comando que invalida y recarga este modelo.

class NetworkProfileModel {
  final String id;
  final String nombre;
  final String descripcion;
  final int cantidadMiembros;
  final String? fotoPerfil;
  final bool esOficial;
  final bool esVerificada;
  final String creadaPor;
  final int publicacionesCount;
  final String? createdAt;

  NetworkProfileModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.cantidadMiembros,
    this.fotoPerfil,
    required this.esOficial,
    required this.esVerificada,
    required this.creadaPor,
    required this.publicacionesCount,
    this.createdAt,
  });

  factory NetworkProfileModel.fromApiMap(Map<String, dynamic> json) {
    return NetworkProfileModel(
      id: parseMongoIdFromMap(json) ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      cantidadMiembros: (json['cantidadMiembros'] as num?)?.toInt() ?? 0,
      fotoPerfil: json['fotoPerfil'] as String?,
      esOficial: json['esOficial'] == true,
      esVerificada: json['esVerificada'] == true,
      creadaPor: json['creadaPor'] as String? ?? '',
      publicacionesCount: (json['publicacionesCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? json['fechaCreacion']?.toString(),
    );
  }
}
