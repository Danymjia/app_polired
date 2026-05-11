import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

/// Resultado genérico de las llamadas API.
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResult({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResult.ok(T data, {String? message, int? statusCode}) =>
      ApiResult(success: true, data: data, message: message, statusCode: statusCode);

  factory ApiResult.error(String message, {int? statusCode}) =>
      ApiResult(success: false, message: message, statusCode: statusCode);
}

/// Servicio base HTTP para comunicarse con el backend de Polired.
class ApiService {
  final http.Client _client;
  String? _token;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── POST ────────────────────────────────────────────────────────────────
  Future<ApiResult<dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResult.error('Sin conexión. Verifica tu red.');
    } on TimeoutException {
      return ApiResult.error('Tiempo de espera agotado. Intenta de nuevo.');
    } catch (e) {
      return ApiResult.error('Error inesperado: $e');
    }
  }

  // ─── PATCH ───────────────────────────────────────────────────────────────
  Future<ApiResult<dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResult.error('Sin conexión. Verifica tu red.');
    } on TimeoutException {
      return ApiResult.error('Tiempo de espera agotado. Intenta de nuevo.');
    } catch (e) {
      return ApiResult.error('Error inesperado: $e');
    }
  }

  // ─── GET ─────────────────────────────────────────────────────────────────
  Future<ApiResult<dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResult.error('Sin conexión. Verifica tu red.');
    } on TimeoutException {
      return ApiResult.error('Tiempo de espera agotado. Intenta de nuevo.');
    } catch (e) {
      return ApiResult.error('Error inesperado: $e');
    }
  }

  ApiResult<dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.ok(decoded, statusCode: response.statusCode);
      } else {
        String msg = 'Error ${response.statusCode}';
        if (decoded is Map) {
          if (decoded.containsKey('msg')) {
            msg = decoded['msg'] as String;
          } else if (decoded.containsKey('errors') && decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
            final firstError = (decoded['errors'] as List).first;
            if (firstError is Map && firstError.containsKey('msg')) {
              msg = firstError['msg'] as String;
            }
          }
        }
        return ApiResult.error(msg, statusCode: response.statusCode);
      }
    } catch (_) {
      return ApiResult.error('Respuesta inválida del servidor', statusCode: response.statusCode);
    }
  }
}
