import 'api_service.dart';
import '../models/post_model.dart';

/// Servicio para interactuar con las publicaciones del backend.
/// Endpoints utilizados:
///   - GET  /publicaciones/global          → feed paginado (red global)
///   - GET  /publicaciones/comunitarias    → feed de comunidades (paginado)
///   - GET  /publicaciones/red/:redId      → feed filtrado por red
///   - POST /estudiantes/publicaciones     → crear publicación simple
class PostService {
  final ApiService _api;

  PostService(this._api);

  // ─── Feed Global (paginado) ───────────────────────────────────────────────
  /// GET /publicaciones/global?page=&limit=
  /// Respuesta: { redId, page, total, items: [ <Publicacion> ] }
  Future<ApiResult<List<PostModel>>> fetchGlobalFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '/publicaciones/global?page=$page&limit=$limit',
    );
    return _parseItems(result);
  }

  // ─── Feed Comunitarias (paginado) ─────────────────────────────────────────
  /// GET /publicaciones/comunitarias?page=&limit=
  /// Respuesta: { page, total, items: [ <Publicacion> ] }
  Future<ApiResult<List<PostModel>>> fetchCommunityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '/publicaciones/comunitarias?page=$page&limit=$limit',
    );
    return _parseItems(result);
  }

  // ─── Feed por Red ─────────────────────────────────────────────────────────
  /// GET /publicaciones/red/:redId
  /// Respuesta: { msg, publicaciones: [ <Publicacion> ] }
  Future<ApiResult<List<PostModel>>> fetchFeedByNetwork(String redId) async {
    final result = await _api.get('/publicaciones/red/$redId');

    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final rawList = data['publicaciones'];
      if (rawList is List) {
        final posts = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => PostModel.fromJson(j))
            .toList();
        return ApiResult.ok(posts);
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar publicaciones');
  }

  // ─── Crear Publicación Simple ─────────────────────────────────────────────
  /// POST /estudiantes/publicaciones
  Future<ApiResult<dynamic>> createPost({
    required String titulo,
    required String contenido,
    required String categoria,
    String? comunidadId,
    String? mediaUrl,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
      'categoria': categoria,
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
    return _api.post('/estudiantes/publicaciones', body);
  }

  // ─── Crear Artículo ───────────────────────────────────────────────────────
  /// POST /publicaciones/articulos
  Future<ApiResult<dynamic>> createArticle({
    required String titulo,
    required String descripcion,
    required double precio,
    String? comunidadId,
    String? imagen,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': 'venta',
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (imagen != null) body['imagen'] = imagen;
    return _api.post('/publicaciones/articulos', body);
  }

  // ─── Crear Publicación Extendida ──────────────────────────────────────────
  /// POST /publicaciones/extendida (social routes)
  Future<ApiResult<dynamic>> createExtendedPost({
    required String titulo,
    String? contenido,
    String? comunidadId,
    String tipoContenido = 'texto',
    String? categoria,
    String? mediaUrl,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'tipoContenido': tipoContenido,
    };
    if (contenido != null) body['contenido'] = contenido;
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (categoria != null) body['categoria'] = categoria;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
    return _api.post('/publicaciones/extendida', body);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  ApiResult<List<PostModel>> _parseItems(ApiResult<dynamic> result) {
    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final rawList = data['items'];
      if (rawList is List) {
        final posts = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => PostModel.fromJson(j))
            .toList();
        return ApiResult.ok(posts);
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar publicaciones');
  }
}
