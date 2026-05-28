import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/poi_model.dart';

class PoiData {
  PoiData._();

  // Lista en memoria — se llena una sola vez con loadFromAssets()
  static List<PoiModel> _all = [];
  static List<PoiModel> get all => _all;

  /// Llama este método UNA vez al arrancar el mapa (antes de _loadMarkers).
  /// Lee el GeoJSON desde assets y convierte cada Feature en un PoiModel.
  static Future<void> loadFromAssets() async {
    if (_all.isNotEmpty) return; // ya cargado

    final raw = await rootBundle.loadString('assets/docs/pois.geojson');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;

    _all = features.map((f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords = f['geometry']['coordinates'] as List<dynamic>;

      return PoiModel(
        id: props['id'] as String,
        name: props['name'] as String,
        shortDescription: props['description'] as String? ?? 'Información por actualizar',
        category: _parseCategory(props['category'] as String? ?? 'edificio'),
        latitude: (coords[1] as num).toDouble(),
        longitude: (coords[0] as num).toDouble(),
        schedule: props['schedule'] != null ? [props['schedule'] as String] : [],
        howToGet: props['howToGet'] as String? ?? 'Indicaciones no disponibles.',
        floor: props['floor'] as String?,
        building: props['building'] as String?,
        phone: props['phone'] as String?,
        email: props['email'] as String?,
      );
    }).toList();
  }

  static PoiCategory _parseCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'academic':
        return PoiCategory.academic;
      case 'services':
        return PoiCategory.services;
      case 'sports':
        return PoiCategory.sports;
      case 'other':
      default:
        return PoiCategory.other;
    }
  }
}
