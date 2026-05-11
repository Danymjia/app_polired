import 'package:flutter/material.dart';
import '../services/network_service.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkService _networkService;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _redes = [];

  NetworkProvider(this._networkService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get redes => _redes;

  Future<void> fetchRedes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.getRedes();
    
    if (result.success && result.data != null) {
      _redes = result.data!;
      _redes.shuffle(); // Mostrar redes de manera aleatoria según requisitos
      if (_redes.length > 5) {
         _redes = _redes.sublist(0, 5); // Tomar solo 5 redes
      }
    } else {
      _errorMessage = result.message;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> unirseRedes(List<String> redesIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (String id in redesIds) {
        final result = await _networkService.unirseRed(id);
        if (!result.success) {
          // If already joined, we might get an error but we can proceed
          if (result.message != null && result.message!.contains("Ya perteneces")) {
            continue;
          }
          _errorMessage = result.message;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
