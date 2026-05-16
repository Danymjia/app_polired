import '../utils/network_acronym.dart';
import '../utils/json_ids.dart';

/// Red comunitaria sugerida (listado general menos las del usuario).
class SuggestedNetworkModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String acronym;

  const SuggestedNetworkModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.acronym,
  });

  factory SuggestedNetworkModel.fromApiMap(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? '';
    return SuggestedNetworkModel(
      id: parseMongoIdFromMap(json) ?? '',
      nombre: nombre,
      descripcion: (json['descripcion'] as String?) ?? '',
      acronym: buildNetworkAcronym(nombre),
    );
  }
}
