import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:polired/services/network_service.dart';
import 'package:polired/services/api_service.dart';
import 'package:polired/config/constants.dart';

// Generará network_service_test.mocks.dart
@GenerateMocks([ApiService])
import 'network_service_test.mocks.dart';

void main() {
  group('NetworkService', () {
    late NetworkService networkService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      networkService = NetworkService(mockApiService);
    });

    test('listar redes (getRedes): obtiene la lista correctamente', () async {
      // Arrange
      final mockData = [
        {'_id': 'red1', 'nombre': 'Comunidad 1'},
        {'_id': 'red2', 'nombre': 'Comunidad 2'},
      ];

      when(mockApiService.get(AppConstants.redesListarEndpoint)).thenAnswer(
        (_) async => ApiResult.ok(mockData),
      );

      // Act
      final result = await networkService.getRedes();

      // Assert
      expect(result.success, true);
      expect(result.data, mockData);
      verify(mockApiService.get(AppConstants.redesListarEndpoint)).called(1);
    });

    test('unirse a red (unirseRed): envía el redId correcto', () async {
      // Arrange
      const redId = 'red_123';
      when(mockApiService.post(AppConstants.unirseRedEndpoint, {'redId': redId}))
          .thenAnswer((_) async => ApiResult.ok({'msg': 'Unido con éxito'}));

      // Act
      final result = await networkService.unirseRed(redId);

      // Assert
      expect(result.success, true);
      verify(mockApiService.post(AppConstants.unirseRedEndpoint, {'redId': redId})).called(1);
    });

    test('abandonar red (salirseRed): envía el redId correcto', () async {
      // Arrange
      const redId = 'red_123';
      final endpoint = '${AppConstants.estudiantesBaseEndpoint}${AppConstants.salirseRedEndpoint}';
      when(mockApiService.post(endpoint, {'redId': redId}))
          .thenAnswer((_) async => ApiResult.ok({'msg': 'Saliste con éxito'}));

      // Act
      final result = await networkService.salirseRed(redId);

      // Assert
      expect(result.success, true);
      verify(mockApiService.post(endpoint, {'redId': redId})).called(1);
    });
  });
}
