import '../config/constants.dart';
import '../models/network_story_model.dart';
import 'api_service.dart';

/// Servicio de redes comunitarias.
/// Endpoints utilizados:
///   - GET /redes/listar                 → todas las redes disponibles
///   - GET /estudiantes/listar/redes     → redes del estudiante autenticado
///   - POST /estudiantes/unirse/red      → suscribir al estudiante a una red
class NetworkService {
  final ApiService _api;

  NetworkService(this._api);

  // ─── Redes del estudiante (lista completa) ────────────────────────────────
  /// GET /estudiantes/listar/redes
  /// Respuesta: { redes: [ { _id, nombre, descripcion } ] }
  Future<ApiResult<int>> getRedesDelEstudiante() async {
    final result = await _api.get(AppConstants.redesEstudianteEndpoint);

    if (result.success && result.data is Map) {
      final redes = (result.data as Map)['redes'];
      if (redes is List) {
        return ApiResult.ok(redes.length);
      }
    }

    return ApiResult.error(result.message ?? 'Error al obtener redes del estudiante');
  }

  /// Devuelve la lista de redes del estudiante como [NetworkStoryModel]
  /// para usarse en el home feed.
  Future<ApiResult<List<NetworkStoryModel>>> getRedesEstudianteStories() async {
    final result = await _api.get(AppConstants.redesEstudianteEndpoint);

    if (result.success && result.data is Map) {
      final rawList = (result.data as Map)['redes'];
      if (rawList is List) {
        final stories = rawList.whereType<Map<String, dynamic>>().map((r) {
          return NetworkStoryModel(
            id: (r['_id'] as String?) ?? '',
            name: (r['nombre'] as String?) ?? '',
            acronym: _buildAcronym(r['nombre'] as String? ?? ''),
            imageUrl: (r['fotoPerfil'] as String?) ?? '',
            isJoined: true,
          );
        }).toList();
        return ApiResult.ok(stories);
      }
    }

    return ApiResult.error(result.message ?? 'Error al obtener redes');
  }

  // ─── Todas las redes disponibles ──────────────────────────────────────────
  /// GET /redes/listar
  /// Respuesta: [ { _id, nombre, descripcion, cantidadMiembros, esOficial, esVerificada } ]
  Future<ApiResult<List<dynamic>>> getRedes() async {
    final result = await _api.get(AppConstants.redesListarEndpoint);

    if (result.success && result.data is List) {
      return ApiResult.ok(result.data as List<dynamic>);
    }

    return ApiResult.error(result.message ?? 'Error al obtener redes comunitarias');
  }

  // ─── Unirse a una red ─────────────────────────────────────────────────────
  /// POST /estudiantes/unirse/red
  Future<ApiResult<dynamic>> unirseRed(String redId) async {
    final result = await _api.post(AppConstants.unirseRedEndpoint, {
      'redId': redId,
    });

    if (result.success) {
      return ApiResult.ok(result.data);
    }

    return ApiResult.error(result.message ?? 'Error al unirse a la red');
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  String _buildAcronym(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, words.first.length.clamp(0, 3)).toUpperCase();
    // Tomar iniciales de palabras importantes (ignorar artículos)
    final stopWords = {'de', 'del', 'la', 'el', 'los', 'las', 'y', 'e', 'o', 'u'};
    final siglas = words.where((w) => !stopWords.contains(w.toLowerCase())).map((w) => w[0].toUpperCase()).join();
    return siglas.substring(0, siglas.length.clamp(0, 5));
  }
}
