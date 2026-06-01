import '../utils/network_acronym.dart';
import '../utils/json_ids.dart';

/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable que representa una red sugerida a la que el usuario aún NO pertenece.
///
/// Flujo dentro de la app:
/// Parseado en `ExploreNetworksProvider` tras consultar las redes globales (Queries).
///
/// Dependencias críticas:
/// - `network_acronym.dart` (para generar fallback visual del avatar).
/// - `json_ids.dart`.
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Solo lectura (Query Side). Unirse a la red se procesa como un Comando HTTP que invalida este DTO eliminándolo de la lista de sugerencias.

/// Red comunitaria sugerida (listado general menos las del usuario).
class SuggestedNetworkModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String acronym;
  final int cantidadMiembros;
  final String? fotoPerfil;

  const SuggestedNetworkModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.acronym,
    this.cantidadMiembros = 0,
    this.fotoPerfil,
  });

  factory SuggestedNetworkModel.fromApiMap(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? '';
    return SuggestedNetworkModel(
      id: parseMongoIdFromMap(json) ?? '',
      nombre: nombre,
      descripcion: (json['descripcion'] as String?) ?? '',
      acronym: buildNetworkAcronym(nombre),
      cantidadMiembros: (json['cantidadMiembros'] as num?)?.toInt() ?? 0,
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }
}
