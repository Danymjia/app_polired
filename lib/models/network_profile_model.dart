import '../utils/json_ids.dart';

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
    );
  }
}
