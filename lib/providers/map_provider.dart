import 'package:flutter/foundation.dart';
import '../models/poi_model.dart';
import '../services/poi_data.dart';

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
