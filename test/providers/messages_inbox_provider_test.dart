import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:polired/providers/messages_inbox_provider.dart';
import 'package:polired/repositories/conversations_repository.dart';
import 'package:polired/services/network_service.dart';
import 'package:polired/services/socket_service.dart';
import 'package:polired/models/user_model.dart';
import 'package:polired/models/conversation_model.dart';
import 'package:polired/services/api_service.dart';

@GenerateMocks([ConversationsRepository, NetworkService, SocketService])
import 'messages_inbox_provider_test.mocks.dart';

void main() {
  group('MessagesInboxProvider', () {
    late MessagesInboxProvider provider;
    late MockConversationsRepository mockRepo;
    late MockNetworkService mockNetworkService;
    late MockSocketService mockSocket;

    final dummyUser = UserModel(
      id: 'user_1',
      nombre: 'Test',
      apellido: 'User',
      email: 'test@test.com',
      roles: ['estudiante'],
      perfilCompleto: true,
    );

    setUp(() {
      mockRepo = MockConversationsRepository();
      mockNetworkService = MockNetworkService();
      mockSocket = MockSocketService();

      // Stub para connectionPhase, necesario en el constructor del Provider
      when(mockSocket.connectionPhase)
          .thenReturn(ValueNotifier(SocketConnectionPhase.connected));

      provider = MessagesInboxProvider(
        conversationsRepository: mockRepo,
        networkService: mockNetworkService,
        socketService: mockSocket,
      );
    });

    test('1. carga inicial de conversaciones y redes', () async {
      // Arrange
      final convs = [
        ConversationModel(
          id: 'conv_1',
          ultimaActividad: DateTime.now(),
          peer: const ChatPeerModel(id: 'user_2', nombre: 'Contact', apellido: '2'),
        ),
        ConversationModel(
          id: 'conv_2',
          ultimaActividad: DateTime.now(),
          peer: const ChatPeerModel(id: 'user_3', nombre: 'Contact', apellido: '3'),
        ),
      ];
      
      when(mockRepo.fetchConversations()).thenAnswer((_) async => ApiResult.ok(convs));
      when(mockNetworkService.getRedesEstudianteStories()).thenAnswer((_) async => ApiResult.ok([]));
      when(mockNetworkService.getRedes()).thenAnswer((_) async => ApiResult.ok([]));
      
      // Act
      provider.onAuthChanged(dummyUser);
      
      // Esperamos el Future.wait interno de _loadInitialForUser
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(provider.listStatus, InboxListStatus.success);
      expect(provider.conversations.length, 2);
      expect(provider.conversations.first.id, 'conv_1');
      verify(mockRepo.fetchConversations()).called(1);
    });

    test('2. reordenamiento de bandeja por evento de socket (nuevo_mensaje)', () async {
      // Arrange
      final convA = ConversationModel(
        id: 'conv_A',
        ultimaActividad: DateTime.now().subtract(const Duration(minutes: 5)),
        peer: const ChatPeerModel(id: 'user_A', nombre: 'Contact', apellido: 'A'),
      );
      final convB = ConversationModel(
        id: 'conv_B',
        ultimaActividad: DateTime.now().subtract(const Duration(minutes: 10)),
        peer: const ChatPeerModel(id: 'user_B', nombre: 'Contact', apellido: 'B'),
      );
      
      when(mockRepo.fetchConversations()).thenAnswer((_) async => ApiResult.ok([convA, convB]));
      when(mockNetworkService.getRedesEstudianteStories()).thenAnswer((_) async => ApiResult.ok([]));
      when(mockNetworkService.getRedes()).thenAnswer((_) async => ApiResult.ok([]));

      provider.onAuthChanged(dummyUser);
      await Future.delayed(Duration.zero);
      
      expect(provider.conversations[0].id, 'conv_A');
      expect(provider.conversations[1].id, 'conv_B');

      final verification = verify(mockSocket.on('nuevo_mensaje', captureAny));
      final Function(dynamic) socketCallback = verification.captured.first as Function(dynamic);

      // Act: Simulamos un mensaje entrante en la conversación B
      final nowStr = DateTime.now().toIso8601String();
      final payload = {
        'mensaje': {
          'conversacionId': 'conv_B',
          'contenido': 'Hola de nuevo!',
          'autor': {'_id': 'user_B'},
          'createdAt': nowStr,
        }
      };

      socketCallback(payload);

      // Assert: La conv B debió saltar al inicio (índice 0)
      expect(provider.conversations.length, 2);
      expect(provider.conversations[0].id, 'conv_B');
      expect(provider.conversations[0].ultimoMensaje?.contenido, 'Hola de nuevo!');
      expect(provider.conversations[1].id, 'conv_A');
    });
  });
}
