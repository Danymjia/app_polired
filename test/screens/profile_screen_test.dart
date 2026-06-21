import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:polired/providers/auth_provider.dart';
import 'package:polired/providers/network_provider.dart';
import 'package:polired/providers/my_profile_feed_provider.dart';
import 'package:polired/providers/post_store_provider.dart';
import 'package:polired/services/socket_service.dart';
import 'package:polired/screens/profile/profile_screen.dart';
import 'package:polired/models/user_model.dart';

@GenerateMocks([
  AuthProvider,
  NetworkProvider,
  MyProfileFeedProvider,
  PostStoreProvider,
  SocketService
])
import 'profile_screen_test.mocks.dart';

void main() {
  late MockAuthProvider mockAuth;
  late MockNetworkProvider mockNetwork;
  late MockMyProfileFeedProvider mockMyFeed;
  late MockPostStoreProvider mockPostStore;
  late MockSocketService mockSocket;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockNetwork = MockNetworkProvider();
    mockMyFeed = MockMyProfileFeedProvider();
    mockPostStore = MockPostStoreProvider();
    mockSocket = MockSocketService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider<NetworkProvider>.value(value: mockNetwork),
          ChangeNotifierProvider<MyProfileFeedProvider>.value(value: mockMyFeed),
          ChangeNotifierProvider<PostStoreProvider>.value(value: mockPostStore),
          Provider<SocketService>.value(value: mockSocket),
        ],
        child: const ProfileScreen(),
      ),
    );
  }

  testWidgets('ProfileScreen renderiza los datos del usuario mockeado correctamente', (WidgetTester tester) async {
    // 1. Arrange: Usuario Mockeado (sin fotoPerfil para no disparar red HTTP)
    final dummyUser = UserModel(
      id: 'test_user_id',
      nombre: 'Carlos',
      apellido: 'Perez',
      email: 'carlos@test.com',
      username: '@carlosp',
      biografia: 'Bio de prueba 123',
      publicacionesCount: 42,
      strikes: [],
      roles: ['estudiante'],
      perfilCompleto: true,
      suspendido: false,
    );

    // Stubs para AuthProvider
    when(mockAuth.user).thenReturn(dummyUser);

    // Stubs para NetworkProvider
    when(mockNetwork.redesCount).thenReturn(5);
    when(mockNetwork.redes).thenReturn([]); // Lista vacía segura
    when(mockNetwork.fetchRedesDelEstudiante()).thenAnswer((_) async {});

    // Stubs para MyProfileFeedProvider
    when(mockMyFeed.postIds).thenReturn([]);
    when(mockMyFeed.isLoadingFeed).thenReturn(false);
    when(mockMyFeed.isLoadingMoreFeed).thenReturn(false);
    when(mockMyFeed.feedError).thenReturn(null);
    when(mockMyFeed.fetchInitialFeed('test_user_id')).thenAnswer((_) async {});

    // 2. Act: Montar el widget inicial
    await tester.pumpWidget(createWidgetUnderTest());

    // CRÍTICO: Disparar el frame post-montaje para ejecutar `addPostFrameCallback`
    await tester.pumpAndSettle();

    // 3. Assert: Verificar la UI visual
    expect(find.text('Carlos Perez'), findsOneWidget); // nombreCompleto (Helper del modelo)
    expect(find.text('@carlosp'), findsOneWidget); // AppBar title
    expect(find.text('Bio de prueba 123'), findsOneWidget);
    expect(find.text('42'), findsOneWidget); // Estadísticas de publicaciones
    expect(find.text('5'), findsOneWidget); // Estadísticas de redes
    
    // Verificar que renderizó las iniciales 'CP' en el avatar por no tener foto HTTP
    expect(find.text('CP'), findsOneWidget); 

    // 4. Assert Lógico: Verificar que el Frame Callback realmente ocurrió
    verify(mockNetwork.fetchRedesDelEstudiante()).called(1);
    verify(mockMyFeed.fetchInitialFeed('test_user_id')).called(1);
    
    // Y verificamos que se registró en el socket de strikes
    verify(mockSocket.on('nuevo_strike', any)).called(1);
  });
}
