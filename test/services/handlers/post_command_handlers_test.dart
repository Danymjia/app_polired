import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:polired/services/handlers/post_command_handlers.dart';
import 'package:polired/services/post_service.dart';
import 'package:polired/providers/post_store_provider.dart';
import 'package:polired/services/navigation_bus.dart';
import 'package:polired/models/commands/feed_command.dart';
import 'package:polired/models/feed_context.dart';
import 'package:polired/models/post_model.dart';
import 'package:polired/services/api_service.dart';
import 'package:polired/models/events/post_event.dart';

@GenerateMocks([PostService, PostStoreProvider, NavigationBus])
import 'post_command_handlers_test.mocks.dart';

void main() {
  group('PostCommandHandlers (CQRS)', () {
    late MockPostService mockPostService;
    late MockPostStoreProvider mockStore;
    late MockNavigationBus mockNavigationBus;

    final dummyPost = PostModel(
      id: 'post_1',
      networkId: 'net_1',
      networkName: 'Network 1',
      authorId: 'user_1',
      authorUsername: 'user1',
      authorFullName: 'User One',
      titulo: 'Test Post',
      contenido: 'Content',
      tipoContenido: 'texto',
      categoria: 'comunidad',
      mediaUrls: [],
      likesCount: 0,
      commentsCount: 0,
      timestamp: DateTime.now(),
    );

    setUp(() {
      mockPostService = MockPostService();
      mockStore = MockPostStoreProvider();
      mockNavigationBus = MockNavigationBus();
      
      // Comportamiento por defecto
      when(mockStore.nextSequenceNumber(any)).thenReturn(1);
    });

    test('1. Eliminar publicación propia (Éxito sin rollback)', () async {
      // Arrange
      final handler = DeletePostCommandHandler(mockPostService, mockStore);
      final command = DeletePostCommand(postId: 'post_1');

      when(mockStore.getPost('post_1')).thenReturn(dummyPost);
      when(mockStore.getContextsForPost('post_1')).thenReturn([FeedContext.home()]);
      
      when(mockPostService.deletePost('post_1', isArticle: false))
          .thenAnswer((_) async => ApiResult.ok({'msg': 'Eliminado'}));

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.success, true);
      
      // Verificamos que se emitió el PostDeleted optimista
      verify(mockStore.applyStateEvent(argThat(isA<PostDeleted>()))).called(1);
      verify(mockPostService.deletePost('post_1', isArticle: false)).called(1);
      
      // Verificamos que NO hubo rollback
      verifyNever(mockStore.applyStateEvent(argThat(isA<PostCreated>())));
    });

    test('2. Eliminar publicación rechazada (Optimistic UI + Rollback en ORDEN)', () async {
      // Arrange
      final handler = DeletePostCommandHandler(mockPostService, mockStore);
      final command = DeletePostCommand(postId: 'post_1');

      when(mockStore.getPost('post_1')).thenReturn(dummyPost);
      when(mockStore.getContextsForPost('post_1')).thenReturn([FeedContext.home()]);
      
      // Simulamos que el backend rechaza la petición porque no es propietario
      when(mockPostService.deletePost('post_1', isArticle: false))
          .thenAnswer((_) async => ApiResult.error('No autorizado', statusCode: 403));

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.success, false);
      expect(result.error, 'No autorizado');
      
      // Verificamos ESTRICTAMENTE el orden:
      // 1° borrado optimista, 2° rollback a creado
      verifyInOrder([
        mockStore.applyStateEvent(argThat(isA<PostDeleted>())),
        mockStore.applyStateEvent(argThat(isA<PostCreated>())),
      ]);
    });

    test('3. Crear publicación (Caso exitoso)', () async {
      // Arrange
      final handler = CreatePostCommandHandler(mockPostService, mockStore, mockNavigationBus);
      final command = CreatePostCommand(
        feedContext: FeedContext.home(),
        content: 'Contenido nuevo',
        category: 'comunidad',
        title: 'Titulo',
        networkId: 'net_1',
        postType: 'texto',
      );

      final responseData = {
        'post': {
          '_id': 'post_1',
          'comunidadId': 'net_1',
          'nombreComunidad': 'Network 1',
          'autorId': 'user_1',
          'usernameAutor': 'user1',
          'nombreAutor': 'User One',
          'titulo': 'Test Post',
          'contenido': 'Content',
          'tipoContenido': 'texto',
          'categoria': 'comunidad',
          'mediaUrls': [],
          'likesCount': 0,
          'commentsCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
        }
      };

      when(mockPostService.createPost(
        feedContext: 'home',
        contenido: 'Contenido nuevo',
        categoria: 'comunidad',
        titulo: 'Titulo',
        comunidadId: 'net_1',
      )).thenAnswer((_) async => ApiResult.ok(responseData));

      // Act
      final result = await handler.handle(command);

      // Assert
      expect(result.success, true);
      expect(result.data, 'publicacion:post_1');
      
      // Verificamos que se despachó al store el evento PostCreated
      verify(mockStore.applyStateEvent(argThat(isA<PostCreated>()))).called(greaterThan(0));
      
      // Verificamos que emitió evento de navegación para enfocar el nuevo post
      verify(mockNavigationBus.dispatch(any)).called(1);
    });
  });
}
