import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'api_service.dart';
import '../models/post_model.dart';

/// Servicio para interactuar con las publicaciones del backend.
/// Endpoints utilizados:
///   - GET  /publicaciones/global           → feed paginado (red global)
///   - GET  /publicaciones/comunitarias     → feed de comunidades (paginado)
///   - GET  /publicaciones/red/:redId       → feed filtrado por red
///   - GET  /publicaciones/articulos/global → artículos globales (Marketplace/Cursos)
///   - POST /estudiantes/publicaciones      → crear publicación simple (Comunidad/Noticias)
///   - POST /publicaciones/articulos        → crear artículo/cursos (Venta/Cursos)
///
/// Nota: `fetchArticlesFeed` consume el endpoint de artículos globales y filtra
/// por `categoria` para distinguir `venta` y `cursos`.
class PostService {
  final ApiService _api;

  PostService(this._api);

  // ─── Feed Global (paginado) ───────────────────────────────────────────────
  /// GET /publicaciones/global?page=&limit=
  Future<ApiResult<List<PostModel>>> fetchGlobalFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '${AppConstants.publicacionesGlobalEndpoint}?page=$page&limit=$limit',
    );
    return _parseItems(result);
  }

  // ─── Feed Comunitarias (paginado) ─────────────────────────────────────────
  /// GET /publicaciones/comunitarias?page=&limit=
  Future<ApiResult<List<PostModel>>> fetchCommunityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '${AppConstants.publicacionesComunidadesEndpoint}?page=$page&limit=$limit',
    );
    return _parseItems(result);
  }

  // ─── Feed de Artículos Globales (Marketplace/Cursos) ──────────────────────
  /// GET /publicaciones/articulos/global?page=&limit=
  Future<ApiResult<List<PostModel>>> fetchArticlesFeed({
    int page = 1,
    int limit = 20,
    String? categoria,
  }) async {
    final result = await _api.get(
      '/publicaciones/articulos/global?page=$page&limit=$limit',
    );
    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final rawList = data['items'];
      if (rawList is List) {
        final posts = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => PostModel.fromJson(j))
            .where((post) {
              if (categoria == null || categoria.isEmpty) return true;
              return post.categoria == categoria.toLowerCase();
            })
            .toList();
        return ApiResult.ok(posts);
      }
    }
    return ApiResult.error(result.message ?? 'Error al cargar artículos');
  }

  // ─── Feed por Red ─────────────────────────────────────────────────────────
  /// GET /publicaciones/red/:redId
  Future<ApiResult<List<PostModel>>> fetchFeedByNetwork(String redId) async {
    final result = await _api.get(
      '${AppConstants.publicacionesPorRedEndpoint}/$redId',
    );

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
    List<String>? mediaUrls,
    List<File>? imageFiles,
  }) async {
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final fields = <String, String>{
        'titulo': titulo,
        'contenido': contenido,
        'categoria': categoria,
        'tipoContenido': 'imagen',
      };
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest(AppConstants.crearPublicacionEndpoint, method: 'POST', fields: fields, files: files);
    }

    final body = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
      'categoria': categoria,
      'tipoContenido': (mediaUrls != null && mediaUrls.isNotEmpty) ? 'imagen' : 'texto',
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
    return _api.post(AppConstants.crearPublicacionEndpoint, body);
  }

  // ─── Crear Artículo ───────────────────────────────────────────────────────
  /// POST /publicaciones/articulos
  Future<ApiResult<dynamic>> createArticle({
    required String titulo,
    required String descripcion,
    required dynamic precio,
    required String categoria,
    String? comunidadId,
    String tipoContenido = 'texto',
    List<String>? mediaUrls,
    List<File>? imageFiles,
  }) async {
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final fields = <String, String>{
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio.toString(),
        'categoria': categoria,
        'tipoContenido': 'imagen',
      };
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest('/publicaciones/articulos', method: 'POST', fields: fields, files: files);
    }

    final body = <String, dynamic>{
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'tipoContenido': tipoContenido,
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
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
    List<String>? mediaUrls,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'tipoContenido': tipoContenido,
    };
    if (contenido != null) body['contenido'] = contenido;
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (categoria != null) body['categoria'] = categoria;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
    return _api.post(AppConstants.crearPublicacionExtendidaEndpoint, body);
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
