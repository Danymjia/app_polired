import '../config/constants.dart';
import '../models/network_story_model.dart';
import '../utils/json_ids.dart';
import '../utils/network_acronym.dart';
import 'api_service.dart';

/// Responsabilidad principal:
/// Repositorio/Servicio para interactuar con el ecosistema de Comunidades/Redes del backend.
///
/// Flujo dentro de la app:
/// Llamado por `NetworkProvider` y `ExploreNetworksProvider` para listar redes (queries) y unirse/salir (commands). Parsea respuestas JSON a DTOs.
///
/// Dependencias críticas:
/// - `ApiService` (Red).
///
/// Side Effects:
/// - Envía Commands HTTP (`unirseRed`, `salirseRed`) que alteran permanentemente el estado en el backend.
///
/// Recordatorios técnicos y CQRS:
/// - Deuda técnica de Capas: Este archivo actúa como un "Service" (transporte HTTP) y como "Repository" (Parseo de JSON a `NetworkStoryModel`). Sería ideal separar la extracción de datos de su transformación a objetos de dominio.
class NetworkService {
  final ApiService _api;

  NetworkService(this._api);

  // ─── Redes del estudiante (lista completa) ────────────────────────────────
  /// GET /estudiantes/listar/redes
  /// Respuesta: { redes: [ { _id | id, nombre, descripcion } ] }
  Future<ApiResult<List<dynamic>>> getRedesDelEstudiante() async {
    final result = await _api.get(AppConstants.redesEstudianteEndpoint);

    if (result.success && result.data is Map) {
      final redes = (result.data as Map)['redes'];
      if (redes is List) {
        return ApiResult.ok(redes);
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
        final stories = <NetworkStoryModel>[];
        for (final item in rawList) {
          if (item is! Map) continue;
          final r = Map<String, dynamic>.from(item);
          final id = parseMongoIdFromMap(r) ?? '';
          if (id.isEmpty) continue;
          stories.add(
            NetworkStoryModel(
              id: id,
              name: (r['nombre'] as String?) ?? '',
              acronym: buildNetworkAcronym(r['nombre'] as String? ?? ''),
              imageUrl: (r['fotoPerfil'] as String?) ?? '',
              isJoined: true,
              esVerificada: r['esVerificada'] == true,
              esOficial: r['esOficial'] == true,
            ),
          );
        }
        return ApiResult.ok(stories);
      }
    }

    return ApiResult.error(result.message ?? 'Error al obtener redes');
  }

  /// Devuelve la lista de redes disponibles (todas) como [NetworkStoryModel]
  /// con isJoined: false, para el caso donde el usuario no tiene redes.
  Future<ApiResult<List<NetworkStoryModel>>> getAvailableNetworksStories() async {
    final result = await _api.get(AppConstants.redesListarEndpoint);

    if (result.success && result.data is List) {
      final rawList = result.data as List;
      final stories = <NetworkStoryModel>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        final r = Map<String, dynamic>.from(item);
        final id = parseMongoIdFromMap(r) ?? '';
        if (id.isEmpty) continue;
        stories.add(
          NetworkStoryModel(
            id: id,
            name: (r['nombre'] as String?) ?? '',
            acronym: buildNetworkAcronym(r['nombre'] as String? ?? ''),
            imageUrl: (r['fotoPerfil'] as String?) ?? '',
            isJoined: false,
            esVerificada: r['esVerificada'] == true,
            esOficial: r['esOficial'] == true,
          ),
        );
      }
      return ApiResult.ok(stories);
    }

    return ApiResult.error(result.message ?? 'Error al obtener redes disponibles');
  }

  // ─── Todas las redes disponibles ──────────────────────────────────────────
  /// GET /redes/listar
  /// Respuesta: [ { _id | id, nombre, descripcion, cantidadMiembros, esOficial, esVerificada } ]
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
    final id = redId.trim();
    if (id.isEmpty) {
      return ApiResult.error('Identificador de red no válido');
    }

    final result = await _api.post(AppConstants.unirseRedEndpoint, {
      'redId': id,
    });

    if (result.success) {
      return ApiResult.ok(result.data);
    }

    return ApiResult.error(result.message ?? 'Error al unirse a la red');
  }

  // ─── Perfil de una red (con paginación de publicaciones) ────────────────
  /// GET /redes/:redId?page=1&limit=10
  Future<ApiResult<Map<String, dynamic>>> getNetworkProfile(String redId, {int page = 1, int limit = 10}) async {
    final id = redId.trim();
    if (id.isEmpty) {
      return ApiResult.error('Identificador de red no válido');
    }

    final result = await _api.get('${AppConstants.redesEndpoint}/$id?page=$page&limit=$limit');

    if (result.success && result.data is Map) {
      return ApiResult.ok(result.data as Map<String, dynamic>);
    }

    return ApiResult.error(result.message ?? 'Error al obtener el perfil de la red');
  }

  // ─── Solicitar creación de nueva red ─────────────────────────────────────
  /// POST /redes/solicitar-creacion
  /// Body: { nombre, descripcion, proposito, fotoPerfil }
  Future<ApiResult<dynamic>> solicitarCreacionRed({
    required String nombre,
    required String descripcion,
    required String proposito,
    String? fotoPerfil,
  }) async {
    final body = {
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'proposito': proposito.trim(),
    };
    if (fotoPerfil != null && fotoPerfil.trim().isNotEmpty) {
      body['fotoPerfil'] = fotoPerfil.trim();
    }
    return await _api.post(AppConstants.redesSolicitarCreacionEndpoint, body);
  }

  // ─── Solicitar verificación de red ────────────────────────────────────────
  Future<ApiResult<dynamic>> solicitarVerificacionRed({
    required String redId,
    required String nombreRed,
    required String fechaCreacionRed,
    required int cantidadMiembros,
    required String correoInstitucional,
  }) async {
    final body = {
      'redId': redId.trim(),
      'nombreRed': nombreRed.trim(),
      'fechaCreacionRed': fechaCreacionRed.trim(),
      'cantidadMiembros': cantidadMiembros,
      'correoInstitucional': correoInstitucional.trim(),
    };
    return await _api.post('${AppConstants.adminRedBaseEndpoint}${AppConstants.redesSolicitarVerificacionEndpoint}', body);
  }

  // ─── Solicitar oficialización de red ──────────────────────────────────────
  Future<ApiResult<dynamic>> solicitarOficializacionRed({
    required String redId,
    required String nombreRed,
    required String fechaCreacionRed,
    required int cantidadMiembros,
    required String dependencia,
    required String cargo,
    required String correoInstitucional,
    required String justificacion,
  }) async {
    final body = {
      'redId': redId.trim(),
      'nombreRed': nombreRed.trim(),
      'fechaCreacionRed': fechaCreacionRed.trim(),
      'cantidadMiembros': cantidadMiembros,
      'dependencia': dependencia.trim(),
      'cargo': cargo.trim(),
      'correoInstitucional': correoInstitucional.trim(),
      'justificacion': justificacion.trim(),
    };
    return await _api.post('${AppConstants.adminRedBaseEndpoint}${AppConstants.redesSolicitarOficializacionEndpoint}', body);
  }

  // ─── Reportar red ─────────────────────────────────────────────────────────
  /// POST /estudiantes/reportes/red
  /// Body: { redId, tipo, descripcion }
  Future<ApiResult<dynamic>> reportNetwork({
    required String redId,
    required String tipo,
    required String descripcion,
  }) async {
    final body = {
      'redId': redId.trim(),
      'tipo': tipo.trim(),
      'descripcion': descripcion.trim(),
    };
    return await _api.post('${AppConstants.estudiantesBaseEndpoint}${AppConstants.reportesRedEndpoint}', body);
  }

  // ─── Abandonar una red ────────────────────────────────────────────────────
  /// POST /estudiantes/salirse/red
  /// Body: { redId }
  Future<ApiResult<dynamic>> salirseRed(String redId) async {
    final body = {
      'redId': redId.trim(),
    };
    return await _api.post('${AppConstants.estudiantesBaseEndpoint}${AppConstants.salirseRedEndpoint}', body);
  }

  // ─── Obtener red asignada al admin ────────────────────────────────────────
  /// GET /admin/red/info
  Future<ApiResult<Map<String, dynamic>>> getAdminNetworkInfo() async {
    final result = await _api.get('/red/admin/informacion');
    if (result.success && result.data is Map) {
      return ApiResult.ok(result.data as Map<String, dynamic>);
    }
    return ApiResult.error(result.message ?? 'Error al obtener red asignada');
  }
}
