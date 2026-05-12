
import 'api_service.dart';

class PostService {
  final ApiService _api;

  PostService(this._api);

  Future<ApiResult<dynamic>> createPost({
    required String titulo,
    required String contenido,
    String? comunidadId,
    String? mediaUrl, 
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
    return _api.post('/estudiantes/publicaciones', body);
  }

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
    };
    if (comunidadId != null) body['comunidadId'] = comunidadId;
    if (imagen != null) body['imagen'] = imagen;
    return _api.post('/publicaciones/articulos', body);
  }
}
