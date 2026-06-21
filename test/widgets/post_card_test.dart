import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:polired/widgets/post_card.dart';
import 'package:polired/providers/post_store_provider.dart';
import 'package:polired/providers/auth_provider.dart';
import 'package:polired/services/command_bus.dart';
import 'package:polired/models/post_model.dart';
import 'package:polired/models/commands/feed_command.dart';
import 'package:polired/models/user_model.dart';

@GenerateMocks([PostStoreProvider, CommandBus, AuthProvider])
import 'post_card_test.mocks.dart';

class TestPostStoreProvider extends ChangeNotifier implements PostStoreProvider {
  PostModel? postToReturn;

  @override
  PostModel? getPost(String id) => postToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestPostStoreProvider mockStore;
  late MockCommandBus mockCommandBus;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockStore = TestPostStoreProvider();
    mockCommandBus = MockCommandBus();
    mockAuth = MockAuthProvider();
  });

  Widget createWidgetUnderTest(PostModel post) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<PostStoreProvider>.value(value: mockStore),
            Provider<CommandBus>.value(value: mockCommandBus),
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ],
          child: PostCard(post: post),
        ),
      ),
    );
  }

  testWidgets('PostCard: El ícono "me gusta" cambia visualmente simulando el ciclo CQRS', (WidgetTester tester) async {
    // 1. Arrange
    const testPostId = 'post_123';
    
    // AuthMock para validar la UI como usuario normal (no autor del post)
    final dummyUser = UserModel(
      id: 'current_user_id',
      nombre: 'Test',
      apellido: 'User',
      email: 'test@test.com',
      roles: ['estudiante'],
      perfilCompleto: true,
    );
    when(mockAuth.user).thenReturn(dummyUser);

    // Post en estado inicial: sin like
    final postUnliked = PostModel(
      id: testPostId,
      authorId: 'user_other',
      authorUsername: '@otro',
      authorFullName: 'Otro Usuario',
      titulo: 'Test Post',
      contenido: 'Este es un post de prueba.',
      tipoContenido: 'publicacion',
      mediaUrls: [], // Vacío para no disparar peticiones HTTP de imágenes
      networkId: '',
      networkName: '',
      categoria: 'general',
      timestamp: DateTime.now(),
      likesCount: 10,
      commentsCount: 2,
      likedByMe: false, // <-- Estado inicial clave
      savedByMe: false,
    );

    // Post en estado futuro: con like (asumiendo que el server respondió OK)
    final postLiked = PostModel(
      id: testPostId,
      authorId: 'user_other',
      authorUsername: '@otro',
      authorFullName: 'Otro Usuario',
      titulo: 'Test Post',
      contenido: 'Este es un post de prueba.',
      tipoContenido: 'publicacion',
      mediaUrls: [],
      networkId: '',
      networkName: '',
      categoria: 'general',
      timestamp: DateTime.now(),
      likesCount: 11,
      commentsCount: 2,
      likedByMe: true, // <-- Estado esperado tras el ciclo
      savedByMe: false,
    );

    // El store provee inicialmente la versión sin like
    mockStore.postToReturn = postUnliked;
    when(mockCommandBus.dispatch(any)).thenAnswer((_) async => CommandResult(success: true));

    // 2. Act: Montar el árbol (aquí Provider llama a mockStore.addListener)
    await tester.pumpWidget(createWidgetUnderTest(postUnliked));
    await tester.pumpAndSettle();

    // 3. Assert Inicial: El widget base tiene el ícono hueco (sin value keys ambiguas)
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    // 4. Act: Usuario hace Tap
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    // 5. Assert de Dispatch (Validación de tipo y payload rigurosa)
    final verification = verify(mockCommandBus.dispatch(captureAny));
    verification.called(1); // Garantiza un solo dispatch
    
    final capturedCommand = verification.captured.first;
    expect(capturedCommand, isA<ToggleLikeCommand>());
    expect((capturedCommand as ToggleLikeCommand).postId, testPostId);

    // 6. Act (Reacción CQRS): Actualizamos la caché local
    mockStore.postToReturn = postLiked;
    
    // Disparamos la reactividad REAL usando el Fake del ChangeNotifier
    mockStore.notifyListeners();
    
    // Avanzamos el tiempo para completar la transición del AnimatedSwitcher
    await tester.pumpAndSettle();

    // 7. Assert Final: El ícono se actualizó dinámicamente sin reconstruir la pantalla
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });
}
