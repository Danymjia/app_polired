import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:polired/services/auth_service.dart';
import 'package:polired/services/api_service.dart';
import 'package:polired/config/constants.dart';

// Este archivo será generado por build_runner
@GenerateMocks([ApiService])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockApiService mockApiService;

    setUp(() {
      // Configuramos valores mock para evitar el error "MissingPluginException"
      // ya que SharedPreferences/SecureStorage llama a código nativo.
      FlutterSecureStorage.setMockInitialValues({});
      
      mockApiService = MockApiService();
      authService = AuthService(mockApiService);
    });

    test('login exitoso: guarda token y usuario, e inyecta token en ApiService', () async {
      // Arrange
      const email = 'test@test.com';
      const password = 'password123';
      final responseData = {
        'token': 'jwt_mock_token',
        'usuario': {
          'id': 'user_1',
          'nombre': 'Test User',
          'email': email,
        }
      };

      when(mockApiService.post(AppConstants.loginEndpoint, any)).thenAnswer(
        (_) async => ApiResult.ok(responseData),
      );

      // Act
      final result = await authService.login(email, password);

      // Assert
      expect(result.success, true);
      expect(result.data, responseData);
      
      verify(mockApiService.post(AppConstants.loginEndpoint, {
        'email': email.trim().toLowerCase(),
        'password': password,
        'context': 'mobile',
      })).called(1);
      verify(mockApiService.setToken('jwt_mock_token')).called(1);
    });

    test('login con credenciales inválidas: retorna fallo y mensaje de error', () async {
      // Arrange
      const email = 'test@test.com';
      const password = 'wrongpassword';
      
      when(mockApiService.post(AppConstants.loginEndpoint, any)).thenAnswer(
        (_) async => ApiResult.error('Credenciales incorrectas', statusCode: 401),
      );

      // Act
      final result = await authService.login(email, password);

      // Assert
      expect(result.success, false);
      expect(result.message, 'Credenciales incorrectas');
      verify(mockApiService.post(AppConstants.loginEndpoint, any)).called(1);
      verifyNever(mockApiService.setToken(any));
    });

    test('recuperación de contraseña: envía email correctamente', () async {
      // Arrange
      const email = 'test@test.com';
      final responseData = {'msg': 'Correo enviado exitosamente'};

      when(mockApiService.post(AppConstants.recuperarPasswordEndpoint, any)).thenAnswer(
        (_) async => ApiResult.ok(responseData),
      );

      // Act
      final result = await authService.forgotPassword(email);

      // Assert
      expect(result.success, true);
      expect(result.message, 'Correo enviado exitosamente');
      verify(mockApiService.post(AppConstants.recuperarPasswordEndpoint, {
        'email': email.trim().toLowerCase(),
      })).called(1);
    });
  });
}
