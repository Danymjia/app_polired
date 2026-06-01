import 'package:flutter/material.dart';
import '../models/suggested_network_model.dart';
import '../services/network_service.dart';

/// Responsabilidad principal:
/// Mantiene el estado de la búsqueda y filtrado local de las redes globales (para sugerencias).
///
/// Flujo dentro de la app:
/// Descarga todas las redes (sin paginar) a través de `NetworkService` y aplica un filtro de texto en memoria al vuelo.
///
/// Dependencias críticas:
/// - `NetworkService` (HTTP).
///
/// Side Effects:
/// - Ninguno fuera de este provider.
///
/// Recordatorios técnicos y CQRS:
/// - Alerta de Escalabilidad: Descarga TODAS las redes en un solo request (`_allNetworks`). Si el número de comunidades crece masivamente, la app podría sufrir OOM (Out of Memory); se requerirá migrar a paginación del lado del servidor.
enum ExploreNetworksStatus { idle, loading, success, error }

class ExploreNetworksProvider extends ChangeNotifier {
  final NetworkService _networkService;

  ExploreNetworksProvider(this._networkService);

  ExploreNetworksStatus _status = ExploreNetworksStatus.idle;
  String? _errorMessage;
  
  List<SuggestedNetworkModel> _allNetworks = [];
  List<SuggestedNetworkModel> _filteredNetworks = [];
  String _searchQuery = '';

  ExploreNetworksStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<SuggestedNetworkModel> get filteredNetworks => _filteredNetworks;
  bool get isLoading => _status == ExploreNetworksStatus.loading;

  Future<void> fetchNetworks() async {
    _status = ExploreNetworksStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.getRedes();
    if (result.success && result.data != null) {
      _allNetworks = result.data!.map((j) => SuggestedNetworkModel.fromApiMap(j as Map<String, dynamic>)).toList();
      _filterNetworks();
      _status = ExploreNetworksStatus.success;
    } else {
      _status = ExploreNetworksStatus.error;
      _errorMessage = result.message ?? 'Error al cargar las redes';
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterNetworks();
    notifyListeners();
  }

  void _filterNetworks() {
    if (_searchQuery.isEmpty) {
      _filteredNetworks = List.from(_allNetworks);
    } else {
      _filteredNetworks = _allNetworks.where((net) {
        final matchName = net.nombre.toLowerCase().contains(_searchQuery);
        final matchDesc = net.descripcion.toLowerCase().contains(_searchQuery);
        return matchName || matchDesc;
      }).toList();
    }
  }
}
