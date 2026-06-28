/// Responsabilidad principal:
/// DTO (Data Transfer Object) inmutable que representa un Punto de Interés (POI) geolocalizado en el campus.
///
/// Flujo dentro de la app:
/// Consumido por el `MapProvider` para renderizar marcadores en `mapbox_maps_flutter`.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Modelo de solo lectura.
///
/// Recordatorios técnicos y CQRS:
/// - No participa del patrón CQRS. Es un modelo estático y de lectura para el subsistema de Mapas.
import 'package:flutter/material.dart';

enum PoiCategory {
  academic,    // Facultades, aulas, laboratorios
  services,    // Biblioteca, secretaría, imprenta
  sports,      // Canchas, gimnasio, piscina
  other,       // Baños, parqueaderos, entradas
}

extension PoiCategoryX on PoiCategory {
  String get label => switch (this) {
    PoiCategory.academic => 'Facultades',
    PoiCategory.services => 'Servicios',
    PoiCategory.sports   => 'Deportes',
    PoiCategory.other    => 'Otros',
  };

  IconData get iconData => switch (this) {
    PoiCategory.academic => Icons.school_rounded,
    PoiCategory.services => Icons.business_center_rounded,
    PoiCategory.sports   => Icons.sports_basketball_rounded,
    PoiCategory.other    => Icons.place_rounded,
  };
}

class PoiModel {
  final String id;
  final String name;
  final String shortDescription;
  final PoiCategory category;
  final double latitude;
  final double longitude;
  final List<String> schedule;       // ['Lun-Vie: 8:00 - 20:00', ...]
  final String howToGet;             // Texto libre paso a paso
  final List<String> photoAssets;   // ['assets/photos/biblioteca_1.jpg', ...]
  final String? floor;
  final String? building;
  final String? buildingNumber;
  final String? phone;
  final String? email;

  const PoiModel({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.schedule,
    required this.howToGet,
    this.photoAssets = const [],
    this.floor,
    this.building,
    this.buildingNumber,
    this.phone,
    this.email,
  });

  String _removeDiacritics(String str) {
    const withDia = 'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜñÑ';
    const withoutDia = 'aeiouAEIOUaeiouAEIOUnN';
    String result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  // Para búsqueda: devuelve true si el query coincide con nombre, desc o categoría
  bool matchesQuery(String query) {
    final q = _removeDiacritics(query).toLowerCase();
    return _removeDiacritics(name).toLowerCase().contains(q) ||
        _removeDiacritics(shortDescription).toLowerCase().contains(q) ||
        _removeDiacritics(category.label).toLowerCase().contains(q) ||
        (_removeDiacritics(building ?? '').toLowerCase().contains(q));
  }
}
