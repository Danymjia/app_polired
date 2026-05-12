import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../models/network_story_model.dart';
import '../models/post_model.dart';

/// Proveedor de estado para las comunidades (redes) y el feed de publicaciones.
/// Gestiona la selección de redes, la carga de posts y la suscripción a comunidades.
class NetworkProvider extends ChangeNotifier {
  final NetworkService _networkService;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _redes = [];

  NetworkProvider(this._networkService) {
    _initMockData();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get redes => _redes;

  // --- Home Feed State ---
  NetworkStoryModel? _selectedNetwork;
  bool _loadingPosts = false;
  bool _emptyFeed = false;
  String? _feedErrorState;
  List<PostModel> _postsByNetwork = [];
  
  List<NetworkStoryModel> _networkStories = [];

  NetworkStoryModel? get selectedNetwork => _selectedNetwork;
  bool get loadingPosts => _loadingPosts;
  bool get emptyFeed => _emptyFeed;
  String? get feedErrorState => _feedErrorState;
  List<PostModel> get postsByNetwork => _postsByNetwork;
  List<NetworkStoryModel> get networkStories => _networkStories;

  void _initMockData() {
    // Mock Networks
    _networkStories = [
      NetworkStoryModel(
        id: '1',
        name: 'Facultad de Ingeniería de Sistemas',
        acronym: 'FIS',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjxA2waQFxqgHrDko8zfvaG6-81jIqOjdXWNipNHgf4mr7pQAxg9PG0EvFrrHHjnPuMizkQConuZG0p9kFbHdyZVs4veNiQdyKx3-EsQ60d0MQaoP1GCMM1maKd4ojz92LXgj3VPMUXYrDMBBCrbBjD_hE5ZP4Qx2T11LnqQGq-4jyE7GuQ_2LGpPwyGWkfaSDup3mOi84bHz4jFjYHWIJS_k58oymPMWD8i49JNWvP2zbM8GABEzdb5YVoRexrH48s7R09hL5vt5Y',
        isJoined: true,
      ),
      NetworkStoryModel(
        id: '2',
        name: 'Escuela de Formación de Tecnólogos',
        acronym: 'ESFOT',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB93qx1T8aakJ8weDalsE4WyXsCC-DknyLqvAAzSoK1UjgoerDiA3a8IoYcN_GTG_SRG5en6rsYo4wdYSueDtTIB1eRXRxD96SRzooHrA54b4096PmNMjJ7U_IWNB9RUUnVjc4q0rWBL98Ju8_QbhO7Po-ixqmq8a8pEZDiQOlHtP2a_djmSWkpgxSNhIqwPDpqtDLv__7Z6qRhrHIx5IM74NxZ4PfNmtAJQtY6U--PTXt-l0hjUEUljgROcxZXb6x8UH1GS3lUr2gQ',
        isJoined: false,
      ),
      NetworkStoryModel(
        id: '3',
        name: 'Facultad de Ingeniería Química y Agroindustria',
        acronym: 'FIQA',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjxA2waQFxqgHrDko8zfvaG6-81jIqOjdXWNipNHgf4mr7pQAxg9PG0EvFrrHHjnPuMizkQConuZG0p9kFbHdyZVs4veNiQdyKx3-EsQ60d0MQaoP1GCMM1maKd4ojz92LXgj3VPMUXYrDMBBCrbBjD_hE5ZP4Qx2T11LnqQGq-4jyE7GuQ_2LGpPwyGWkfaSDup3mOi84bHz4jFjYHWIJS_k58oymPMWD8i49JNWvP2zbM8GABEzdb5YVoRexrH48s7R09hL5vt5Y',
        isJoined: false,
      ),
      NetworkStoryModel(
        id: '4',
        name: 'Facultad de Ingeniería Eléctrica y Electrónica',
        acronym: 'FIEE',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCoUnhABTZISoIDCp0F5gqm4vfE8pbaCebLDECNMMTzPe54VZTBl6exLKYl4PkVdG6vPni6LK-uZb7r689R1MM5ADQhvS-5xG6WIT8p4h8bruwQQErQa1xxLz8kNvwHwsZmEYTAGeigBZUEoPxgLmngxG1s2QmhJMT__QAhzfqBveX0Dem4MRxSniSb5-CIqPTGygM2KLvKo3zCk8l9fYJauAD9cY_DP23xGP9HAX-rwUvgLm9AZrZ860VYPlHhG80pspxUQTv77wEX',
        isJoined: false,
      ),
      NetworkStoryModel(
        id: '5',
        name: 'Facultad de Ingeniería Civil y Ambiental',
        acronym: 'FICA',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBZhFnJZO86e7-A8fMf1_D8INYWtBt8zCTZQ0mS4SzKcgrzz1nOeuwUcmAUvtt8hiibz90YUvWxG5xDihCU7TvffbYZHSVI34c2mmFB_gBulGYOYIMCUKyeEHaJHPqFu16VrUmZ237jKfLXNWAJizqHAz5xIyrXqKyxQ9F9bNcus-cpEcP_Aq83WAzRjdFptuCEkLMcC3pxEDIYByY7w0ZSoea_mkLnFinGKsBC63lNzhKxEk0qDyt0Kz6PrArqEsbkuHST7mOe27xh',
        isJoined: false,
      ),
    ];
    
    // Auto select first joined network
    if (_networkStories.isNotEmpty) {
      selectNetwork(_networkStories.first);
    }
  }

  Future<void> selectNetwork(NetworkStoryModel network) async {
    if (_selectedNetwork?.id == network.id) return;

    _selectedNetwork = network;
    _loadingPosts = true;
    _emptyFeed = false;
    _feedErrorState = null;
    notifyListeners();

    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 600));

    if (!network.isJoined) {
      _postsByNetwork = [];
      _loadingPosts = false;
      _emptyFeed = true;
      notifyListeners();
      return;
    }

    // Mock Posts based on network selection
    _postsByNetwork = [
      PostModel(
        id: 'p1',
        networkId: network.id,
        authorUsername: 'clara_design',
        authorImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAAQW8-QD6graUWnBIMa1VxYloDYn9zN8_Xgk-cuwJ_cUFoKgvp-8F0IoTi1XmmqLI6mjfKy0mbaDXtAbyGpmglA4Rd0LfFwhptRE9OQKUrqJWVdRFPJJJJ6UzhAzRE-GR7p8UVqZt0eP_NR_dXI4RLj7WAa-D3QI2xhnppxbTx9phnaoAz2PDXd20XpiV1svZ02l-wMo2jCbn15jRu6FW-F2LSLmPmDXtntX0r3lgHdP9m-xmpNX2YdHS6wE9ofgpRl2IocdiBeWpv',
        isVerified: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA54_IdhCG2VrDp5EZiGIG5_fOXqe-NFdEpn4xtuiezZBFkT0vIdqIkr0jM3sUbBiV00hlywKOUQL3z8FX4KCEhmymluTES03sU4Bt6Q8bYS-v3CY2j4QFefVANWmn7vvUspWTOGtFW-LzWIGrkmJCKxWiQ5a2zeZNF95_eGlHqPvH5Aq-GSA_V0b-usfhj3cqpRSEhxdc3684efcqYueCEd-9a6oXuX5BZBI3XZ5XPZSv5INsSXFhxjRokp0gePY6E1Gpe8f5R-rzq',
        likesCount: 1234,
        content: 'Implementando Clean Architecture en mi nuevo proyecto de Flutter. La separación de capas es clave para el mantenimiento a largo plazo. 🚀 #flutter #cleanarchitecture #software',
        commentsCount: 12,
        timeAgo: 'HACE 2 HORAS',
      ),
      PostModel(
        id: 'p2',
        networkId: network.id,
        authorUsername: 'alex.dev',
        authorImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBntt5o0nD0_ZXoxMZizYM08LXhCVr5vxIZUL0RDu83KyeFLXUbyrP--uBYybEorsbIZjr5yqm3s-iB9gw2D53jPCY-NR5LcKoc2SGdRCMq0NOo2hJnoolmCBmi2vCLXJ5B8EIBaUy4mBUf5OsLOKo5w0N7k5peNHBxGXvuPw-JZpXt-w2HsnqJnBiTu05J0FSEqPjRAS0IXnN64Z_cDngRej3QviWqXZA46EpyBSYvU9V1_XJyvT9NiDk8MDng0ARnHFMgrxYRrqYp',
        isVerified: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBzuer3zJvVg_8_Gj0NC1QXn0r04U42z7uzgEQNqQJoE8Mfe5K7de-q2fDCGIP2snpggqvqa5VvVJ2whZ7vM4dBikzmtLTSAgSKY5ZshNZptseFcf5tx6baZ2Ij6dQ1tphXHbJE4CeyPq2MeKPTyIrDgdMs5rg3Ov1OA4My3ti4wicO2aduc_-ccpuujUAF7ZTDJEqYh2RiY5kw2wAsZqMfDdHAFBBhyi7gsAk8o6Q7GIxG4fGji2An5pFcieGP5UR_NfkFoebhegBl',
        likesCount: 856,
        content: 'Sesiones de debugging a las 3 AM... el pan de cada día de un ingeniero de software. ¡Pero el bug por fin está muerto! 🐛💻 #softwareengineering #debugging #devlife',
        commentsCount: 45,
        timeAgo: 'HACE 5 HORAS',
      ),
    ];

    _loadingPosts = false;
    _emptyFeed = _postsByNetwork.isEmpty;
    notifyListeners();
  }

  // Original NetworkService Methods
  Future<void> fetchRedes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _networkService.getRedes();
    
    if (result.success && result.data != null) {
      _redes = result.data!;
      _redes.shuffle(); 
      if (_redes.length > 5) {
         _redes = _redes.sublist(0, 5); 
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
