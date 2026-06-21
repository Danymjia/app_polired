import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:polired/providers/explore_networks_provider.dart';
import 'package:polired/services/network_service.dart';
import 'package:polired/services/api_service.dart';

// Generará explore_networks_provider_test.mocks.dart
@GenerateMocks([NetworkService])
import 'explore_networks_provider_test.mocks.dart';

void main() {
  group('ExploreNetworksProvider', () {
    late ExploreNetworksProvider provider;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockNetworkService = MockNetworkService();
      provider = ExploreNetworksProvider(mockNetworkService);
    });

    test('fetchNetworks: carga las redes y actualiza el estado a success', () async {
      // Arrange
      final mockData = [
        {
          '_id': 'red1',
          'nombre': 'Ingeniería',
          'descripcion': 'Facultad de ingeniería',
          'fotoPerfil': '',
          'cantidadMiembros': 100,
          'esOficial': true,
          'esVerificada': true
        },
      ];

      when(mockNetworkService.getRedes()).thenAnswer(
        (_) async => ApiResult.ok(mockData),
      );

      // Act
      await provider.fetchNetworks();

      // Assert
      expect(provider.status, ExploreNetworksStatus.success);
      expect(provider.filteredNetworks.length, 1);
      expect(provider.filteredNetworks.first.nombre, 'Ingeniería');
      verify(mockNetworkService.getRedes()).called(1);
    });
  });
}
