import 'dart:io';
import 'package:flutter/foundation.dart';
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
    String? titulo,
    required String contenido,
    required String categoria,
    String? comunidadId,
    List<String>? mediaUrls,
    List<File>? imageFiles,
  }) async {
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final fields = <String, String>{
        'contenido': contenido,
        'categoria': categoria,
        'tipoContenido': 'imagen',
      };
      if (titulo != null && titulo.isNotEmpty) fields['titulo'] = titulo;
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest(AppConstants.crearPublicacionEndpoint, method: 'POST', fields: fields, files: files);
    }

    final body = <String, dynamic>{
      'contenido': contenido,
      'categoria': categoria,
      'tipoContenido': (mediaUrls != null && mediaUrls.isNotEmpty) ? 'imagen' : 'texto',
    };
    if (titulo != null && titulo.isNotEmpty) body['titulo'] = titulo;
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
    return _api.post(AppConstants.crearPublicacionEndpoint, body);
  }

  // ─── Crear Artículo ───────────────────────────────────────────────────────
  /// POST /publicaciones/articulos
  Future<ApiResult<dynamic>> createArticle({
    String? titulo,
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
        'descripcion': descripcion,
        'precio': precio.toString(),
        'categoria': categoria,
        'tipoContenido': 'imagen',
      };
      if (titulo != null && titulo.isNotEmpty) fields['titulo'] = titulo;
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest('/publicaciones/articulos', method: 'POST', fields: fields, files: files);
    }

    final body = <String, dynamic>{
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'tipoContenido': tipoContenido,
    };
    if (titulo != null && titulo.isNotEmpty) body['titulo'] = titulo;
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

  // ─── Interacciones Sociales ───────────────────────────────────────────────
  
  String cleanId(String id) => id.split(':').last;

  /// DELETE /publicaciones/eliminar/:id o /publicaciones/articulo/eliminar/:id
  Future<ApiResult<dynamic>> deletePost(String postId, {required bool isArticle}) async {
    final rawId = cleanId(postId);
    final endpoint = isArticle
        ? '/publicaciones/articulo/eliminar/$rawId'
        : '/publicaciones/eliminar/$rawId';
    return await _api.delete(endpoint);
  }

  /// POST /publicaciones/:id/like o DELETE /publicaciones/:id/like
  Future<bool> toggleLike(String postId, bool isCurrentlyLiked) async {
    final rawId = cleanId(postId);
    final endpoint = '/publicaciones/$rawId/like';
    final result = isCurrentlyLiked ? await _api.delete(endpoint) : await _api.post(endpoint, {});
    return result.success;
  }

  /// POST /publicaciones/:id/guardar o DELETE /publicaciones/:id/guardar
  Future<bool> toggleSave(String postId, bool isCurrentlySaved) async {
    final rawId = cleanId(postId);
    final endpoint = '/publicaciones/$rawId/guardar';
    final result = isCurrentlySaved ? await _api.delete(endpoint) : await _api.post(endpoint, {});
    return result.success;
  }

  /// GET /publicaciones/:id/comentarios/arbol
  Future<ApiResult<dynamic>> getCommentsTree(String postId) async {
    final rawId = cleanId(postId);
    return await _api.get('/publicaciones/$rawId/comentarios/arbol');
  }

  /// GET /publicaciones/:id/likes
  Future<ApiResult<List<dynamic>>> getPostLikes(String postId) async {
    final rawId = cleanId(postId);
    final result = await _api.get('/publicaciones/$rawId/likes');
    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final likes = data['likes'];
      if (likes is List) {
        return ApiResult.ok(likes);
      }
    }
    return ApiResult.error(result.message ?? 'Error al obtener personas que dieron like');
  }

  /// POST /reportes/publicacion
  Future<ApiResult<dynamic>> reportPost({
    required String postId,
    required String tipo,
    required String descripcion,
  }) async {
    final rawId = cleanId(postId);
    String normalizedTipo = tipo;
    final lower = tipo.toLowerCase();
    if (lower == 'contenido inapropiado') {
      normalizedTipo = 'Contenido Inapropiado';
    } else if (lower == 'spam') {
      normalizedTipo = 'Spam';
    } else if (lower == 'acoso o bullying') {
      normalizedTipo = 'Acoso o Bullying';
    } else if (lower == 'información falsa') {
      normalizedTipo = 'Información falsa';
    } else if (lower == 'otro') {
      normalizedTipo = 'Otro';
    }

    final body = {
      'publicacionId': rawId,
      'tipo': normalizedTipo,
      'descripcion': descripcion,
    };
    return await _api.post('/reportes/publicacion', body);
  }

  /// POST /publicaciones/:id/comentarios
  Future<ApiResult<dynamic>> createComment(String postId, String contenido) async {
    final rawId = cleanId(postId);
    return await _api.post('/publicaciones/$rawId/comentarios', {'contenido': contenido});
  }

  /// POST /comentarios/:commentId/responder
  Future<ApiResult<dynamic>> replyComment(String commentId, String contenido) async {
    return await _api.post('/comentarios/$commentId/responder', {'contenido': contenido});
  }

  /// GET /usuarios/guardados
  Future<ApiResult<List<PostModel>>> fetchSavedPosts() async {
    try {
      final result = await _api.get('/usuarios/guardados');
      if (result.success && result.data is Map) {
        final data = result.data as Map<String, dynamic>;
        final rawList = data['guardados'] ?? data['items'] ?? data['publicaciones'];
        if (rawList is List) {
          final List<PostModel> posts = [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                posts.add(PostModel.fromJson(item));
              } catch (e, stack) {
                debugPrint('PostService.fetchSavedPosts: Error parsing item: $item\nError: $e\n$stack');
              }
            }
          }
          return ApiResult.ok(posts);
        } else {
          debugPrint('PostService.fetchSavedPosts: Raw list is not a List: $rawList');
        }
      } else {
        debugPrint('PostService.fetchSavedPosts: Request failed or data is not a Map: ${result.message}');
      }
    } catch (e, stack) {
      debugPrint('PostService.fetchSavedPosts: Exception caught: $e\n$stack');
    }
    return ApiResult.error('Error al cargar publicaciones guardadas');
  }

  /// GET /usuarios/likes?page=&limit=
  Future<ApiResult<List<PostModel>>> fetchLikedPosts({int page = 1, int limit = 20}) async {
    try {
      final result = await _api.get('/usuarios/likes?page=$page&limit=$limit');
      if (result.success && result.data is Map) {
        final data = result.data as Map<String, dynamic>;
        final rawList = data['likes'] ?? data['liked'] ?? data['items'] ?? data['publicaciones'];
        if (rawList is List) {
          final List<PostModel> posts = [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                posts.add(PostModel.fromJson(item));
              } catch (e, stack) {
                debugPrint('PostService.fetchLikedPosts: Error parsing item: $item\nError: $e\n$stack');
              }
            }
          }
          return ApiResult.ok(posts);
        } else {
          debugPrint('PostService.fetchLikedPosts: Raw list is not a List: $rawList');
        }
      } else {
        debugPrint('PostService.fetchLikedPosts: Request failed or data is not a Map: ${result.message}');
      }
    } catch (e, stack) {
      debugPrint('PostService.fetchLikedPosts: Exception caught: $e\n$stack');
    }
    return ApiResult.error('Error al cargar publicaciones gustadas');
  }

  /// POST /reportes/app
  Future<ApiResult<dynamic>> reportApp({
    required String tipo,
    required String descripcion,
  }) async {
    final body = {
      'tipo': tipo,
      'descripcion': descripcion,
    };
    return await _api.post('/reportes/app', body);
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
