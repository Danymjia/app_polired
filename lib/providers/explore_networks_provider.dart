import 'package:flutter/material.dart';
import '../models/suggested_network_model.dart';
import '../services/network_service.dart';

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
