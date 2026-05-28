enum PoiCategory {
  academic,    // Facultades, aulas, laboratorios
  services,    // Biblioteca, secretaría, imprenta
  food,        // Cafeterías, comedores, kioscos
  sports,      // Canchas, gimnasio, piscina
  admin,       // Rectorado, DOBE, financiero
  other,       // Baños, parqueaderos, entradas
}

extension PoiCategoryX on PoiCategory {
  String get label => switch (this) {
    PoiCategory.academic => 'Académico',
    PoiCategory.services => 'Servicios',
    PoiCategory.food     => 'Alimentación',
    PoiCategory.sports   => 'Deportes',
    PoiCategory.admin    => 'Administración',
    PoiCategory.other    => 'Otros',
  };

  String get svgIcon => switch (this) {
    PoiCategory.academic => 'assets/icons/poi_academic.svg',
    PoiCategory.services => 'assets/icons/poi_services.svg',
    PoiCategory.food     => 'assets/icons/poi_food.svg',
    PoiCategory.sports   => 'assets/icons/poi_sports.svg',
    PoiCategory.admin    => 'assets/icons/poi_admin.svg',
    PoiCategory.other    => 'assets/icons/poi_other.svg',
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
    this.phone,
    this.email,
  });

  // Para búsqueda: devuelve true si el query coincide con nombre, desc o categoría
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        shortDescription.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        (building?.toLowerCase().contains(q) ?? false);
  }
}
