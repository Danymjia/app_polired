import 'package:flutter/foundation.dart';
import '../models/poi_model.dart';
import '../services/poi_data.dart';

/// Responsabilidad principal:
/// Mantiene el estado interactivo de la UI del Mapa del Campus (puntos de interés, cámara, selección y filtros visuales).
///
/// Flujo dentro de la app:
/// Actúa de capa intermedia síncrona entre los paneles interactivos (búsqueda, cajón lateral) y el controlador de Mapbox (`mapbox_maps_flutter`).
///
/// Dependencias críticas:
/// - Estructura estática `PoiData`.
///
/// Side Effects:
/// - Controla la visibilidad global de las etiquetas (`showMarkerLabels`) según el zoom de la cámara reportado.
///
/// Recordatorios técnicos y CQRS:
/// - Estado completamente síncrono. No hace llamadas a red, todo se lee de listas hardcodeadas localmente. 
class MapProvider extends ChangeNotifier {
  // Estado de la cámara
  bool _showMarkerLabels = true;
  bool get showMarkerLabels => _showMarkerLabels;

  // POI seleccionado
  PoiModel? _selectedPoi;
  PoiModel? get selectedPoi => _selectedPoi;

  // Búsqueda
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<PoiModel> get searchResults {
    if (_searchQuery.isEmpty) return [];
    return PoiData.all
        .where((poi) => poi.matchesQuery(_searchQuery))
        .toList();
  }

  // Directorio por categorías
  Map<PoiCategory, List<PoiModel>> get poiByCategory {
    final map = <PoiCategory, List<PoiModel>>{};
    for (final poi in PoiData.all) {
      map.putIfAbsent(poi.category, () => []).add(poi);
    }
    return map;
  }

  // Categoría seleccionada en el directorio (para filtrar)
  PoiCategory? _activeCategory;
  PoiCategory? get activeCategory => _activeCategory;

  // --- Métodos ---

  void onZoomChanged(double zoom) {
    final shouldShow = zoom >= 16.5;
    if (shouldShow != _showMarkerLabels) {
      _showMarkerLabels = shouldShow;
      notifyListeners();
    }
  }

  void selectPoi(PoiModel poi) {
    _selectedPoi = poi;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPoi = null;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setActiveCategory(PoiCategory? category) {
    _activeCategory = category;
    notifyListeners();
  }
}
