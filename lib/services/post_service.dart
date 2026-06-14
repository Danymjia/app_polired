import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'api_service.dart';
import '../models/post_model.dart';

/// Responsabilidad principal:
/// Mega-Servicio (Data Layer) que orquesta TODAS las peticiones HTTP relacionadas con Publicaciones, Feeds e Interacciones Sociales.
///
/// Flujo dentro de la app:
/// Usado transversalmente. `GlobalFeedProvider` y otros le piden Feeds (Queries), y los `CommandHandlers` le piden ejecutar creaciones/likes (Commands). Transforma las respuestas en `PostModel`.
///
/// Dependencias críticas:
/// - `ApiService` (Cliente REST).
///
/// Side Effects:
/// - Mutaciones HTTP: Creación de Posts (soporta uploads binarios vía `multipartRequest`), Borrado, Likes y Guardados.
///
/// Recordatorios técnicos y CQRS:
/// - Antipatrón God Object: Este servicio maneja demasiadas responsabilidades simultáneas (Lectura de Feeds, Escritura de Posts, Reportes, Comentarios). Para una arquitectura CQRS pura, debería dividirse en `PostQueryService` (Read) y `PostCommandService` (Write).
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

  // ─── Feed de Artículos Globales (Marketplace/Cursos) ──────────────────────────────────────────
  /// GET /publicaciones/articulos/global?page=&limit=&categoria=
  /// El backend filtra por categoría en servidor (no más filtrado cliente).
  Future<ApiResult<List<PostModel>>> fetchArticlesFeed({
    int page = 1,
    int limit = 20,
    String? categoria,
  }) async {
    String url = '/publicaciones/articulos/global?page=$page&limit=$limit';
    if (categoria != null && categoria.isNotEmpty) {
      url += '&categoria=${Uri.encodeComponent(categoria.toLowerCase())}';
    }
    final result = await _api.get(url);
    return _parseItems(result);
  }

  // ─── Feed por Red (paginado) ────────────────────────────────────────────────────────────────────────────
  /// GET /publicaciones/red/:redId?page=&limit=
  /// Ahora paginado – el backend devuelve { items: [...], total: N }
  Future<ApiResult<List<PostModel>>> fetchFeedByNetwork(
    String redId, {
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      '${AppConstants.publicacionesPorRedEndpoint}/$redId?page=$page&limit=$limit',
    );
    return _parseItems(result);
  }

  // ─── Crear Publicación Simple ─────────────────────────────────────────────
  /// POST /estudiantes/publicaciones
  Future<ApiResult<dynamic>> createPost({
    required String feedContext,
    String? titulo,
    required String contenido,
    required String categoria,
    String? comunidadId,
    List<String>? mediaUrls,
    List<File>? imageFiles,
    double aspectRatio = 1.0,
  }) async {
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final fields = <String, String>{
        'feedContext': feedContext,
        'contenido': contenido,
        'categoria': categoria,
        'tipoContenido': 'imagen',
        'aspectRatio': aspectRatio.toString(),
      };
      if (titulo != null && titulo.isNotEmpty) fields['titulo'] = titulo;
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest(
        AppConstants.crearPublicacionEndpoint,
        method: 'POST',
        fields: fields,
        files: files,
      );
    }

    final body = <String, dynamic>{
      'feedContext': feedContext,
      'contenido': contenido,
      'categoria': categoria,
      'tipoContenido': (mediaUrls != null && mediaUrls.isNotEmpty)
          ? 'imagen'
          : 'texto',
      'aspectRatio': aspectRatio,
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
    required String feedContext,
    String? titulo,
    required String descripcion,
    required dynamic precio,
    required String categoria,
    String? comunidadId,
    String tipoContenido = 'texto',
    List<String>? mediaUrls,
    List<File>? imageFiles,
    double aspectRatio = 1.0,
  }) async {
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final fields = <String, String>{
        'feedContext': feedContext,
        'descripcion': descripcion,
        'precio': precio.toString(),
        'categoria': categoria,
        'tipoContenido': 'imagen',
        'aspectRatio': aspectRatio.toString(),
      };
      if (titulo != null && titulo.isNotEmpty) fields['titulo'] = titulo;
      if (comunidadId != null) fields['comunidadId'] = comunidadId;
      final files = <http.MultipartFile>[];
      for (final file in imageFiles) {
        files.add(await http.MultipartFile.fromPath('imagen', file.path));
      }
      return _api.multipartRequest(
        '/publicaciones/articulos',
        method: 'POST',
        fields: fields,
        files: files,
      );
    }

    final body = <String, dynamic>{
      'feedContext': feedContext,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'tipoContenido': tipoContenido,
      'aspectRatio': aspectRatio,
    };
    if (titulo != null && titulo.isNotEmpty) body['titulo'] = titulo;
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
    return _api.post(AppConstants.publicacionesArticulosEndpoint, body);
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
  Future<ApiResult<dynamic>> deletePost(
    String postId, {
    required bool isArticle,
  }) async {
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
    final result = isCurrentlyLiked
        ? await _api.delete(endpoint)
        : await _api.post(endpoint, {});
    return result.success;
  }

  /// POST /publicaciones/:id/guardar o DELETE /publicaciones/:id/guardar
  Future<bool> toggleSave(String postId, bool isCurrentlySaved) async {
    final rawId = cleanId(postId);
    final endpoint = '/publicaciones/$rawId/guardar';
    final result = isCurrentlySaved
        ? await _api.delete(endpoint)
        : await _api.post(endpoint, {});
    return result.success;
  }

  /// GET /publicaciones/:id/comentarios/arbol
  Future<ApiResult<dynamic>> getCommentsTree(String postId) async {
    final rawId = cleanId(postId);
    return await _api.get('${AppConstants.comentariosEndpoint}/$rawId/comentarios/arbol');
  }

  /// GET /publicaciones/:id/likes
  Future<ApiResult<List<dynamic>>> getPostLikes(String postId) async {
    final rawId = cleanId(postId);
    final result = await _api.get('${AppConstants.likeEndpoint}/$rawId/likes');
    if (result.success && result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      final likes = data['likes'];
      if (likes is List) {
        return ApiResult.ok(likes);
      }
    }
    return ApiResult.error(
      result.message ?? 'Error al obtener personas que dieron like',
    );
  }

  /// POST /reportes/publicacion
  Future<ApiResult<dynamic>> reportarPublicacion({
    required String publicacionId,
    required String tipo,
    required String descripcion,
  }) async {
    final rawId = cleanId(publicacionId);
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
    return await _api.post(AppConstants.reportesPublicacionEndpoint, body);
  }

  /// POST /reportes/articulo
  Future<ApiResult<dynamic>> reportarArticulo({
    required String articuloId,
    required String tipo,
    required String descripcion,
  }) async {
    final rawId = cleanId(articuloId);
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
      'articuloId': rawId,
      'tipo': normalizedTipo,
      'descripcion': descripcion,
    };
    return await _api.post(AppConstants.reportesArticuloEndpoint, body);
  }

  /// POST /publicaciones/:id/comentarios
  Future<ApiResult<dynamic>> createComment(
    String postId,
    String contenido,
  ) async {
    final rawId = cleanId(postId);
    return await _api.post('${AppConstants.comentariosEndpoint}/$rawId/comentarios', {
      'contenido': contenido,
    });
  }

  /// POST /comentarios/:commentId/responder
  Future<ApiResult<dynamic>> replyComment(
    String commentId,
    String contenido,
  ) async {
    return await _api.post('${AppConstants.respuestasComentarioEndpoint}/$commentId/responder', {
      'contenido': contenido,
    });
  }

  /// GET /usuarios/guardados
  Future<ApiResult<List<PostModel>>> fetchSavedPosts() async {
    try {
      final result = await _api.get(AppConstants.usuariosGuardadosEndpoint);
      if (result.success && result.data is Map) {
        final data = result.data as Map<String, dynamic>;
        final rawList =
            data['guardados'] ?? data['items'] ?? data['publicaciones'];
        if (rawList is List) {
          final List<PostModel> posts = [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                posts.add(PostModel.fromJson(item));
              } catch (e, stack) {
                debugPrint(
                  'PostService.fetchSavedPosts: Error parsing item: $item\nError: $e\n$stack',
                );
              }
            }
          }
          return ApiResult.ok(posts);
        } else {
          debugPrint(
            'PostService.fetchSavedPosts: Raw list is not a List: $rawList',
          );
        }
      } else {
        debugPrint(
          'PostService.fetchSavedPosts: Request failed or data is not a Map: ${result.message}',
        );
      }
    } catch (e, stack) {
      debugPrint('PostService.fetchSavedPosts: Exception caught: $e\n$stack');
    }
    return ApiResult.error('Error al cargar publicaciones guardadas');
  }

  /// GET /usuarios/likes?page=&limit=
  Future<ApiResult<List<PostModel>>> fetchLikedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _api.get('${AppConstants.usuariosLikesEndpoint}?page=$page&limit=$limit');
      if (result.success && result.data is Map) {
        final data = result.data as Map<String, dynamic>;
        final rawList =
            data['likes'] ??
            data['liked'] ??
            data['items'] ??
            data['publicaciones'];
        if (rawList is List) {
          final List<PostModel> posts = [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                posts.add(PostModel.fromJson(item));
              } catch (e, stack) {
                debugPrint(
                  'PostService.fetchLikedPosts: Error parsing item: $item\nError: $e\n$stack',
                );
              }
            }
          }
          return ApiResult.ok(posts);
        } else {
          debugPrint(
            'PostService.fetchLikedPosts: Raw list is not a List: $rawList',
          );
        }
      } else {
        debugPrint(
          'PostService.fetchLikedPosts: Request failed or data is not a Map: ${result.message}',
        );
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
    final body = {'tipo': tipo, 'descripcion': descripcion};
    return await _api.post(AppConstants.reportesAppEndpoint, body);
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
