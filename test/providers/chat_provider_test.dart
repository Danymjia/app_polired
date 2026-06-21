import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:polired/providers/chat_provider.dart';
import 'package:polired/services/socket_service.dart';

@GenerateMocks([SocketService, http.Client])
import 'chat_provider_test.mocks.dart';

void main() {
  group('ChatProvider', () {
    late ChatProvider provider;
    late MockSocketService mockSocket;
    late MockClient mockClient;

    setUp(() {
      mockSocket = MockSocketService();
      mockClient = MockClient();

      // Mismo stub que requería el Inbox para el valor de connectionPhase
      when(mockSocket.connectionPhase)
          .thenReturn(ValueNotifier(SocketConnectionPhase.connected));
          
      // NOTA: Instanciamos `provider` dentro de cada test DESPUÉS de preparar
      // los mocks HTTP (client.get/client.post) porque su constructor dispara 
      // peticiones asíncronas inmediatamente.
    });

    test('1. Carga de historial (invierte el orden cronológico de la API)', () async {
      // Arrange
      final fakeResponse = {
        'mensajes': [
          {
            '_id': 'msg_old',
            'conversacionId': 'conv_1',
            'autorId': 'other_user',
            'destinatarioId': 'my_user',
            'contenido': 'Hola',
            'leido': true,
            'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()
          },
          {
            '_id': 'msg_new',
            'conversacionId': 'conv_1',
            'autorId': 'my_user',
            'destinatarioId': 'other_user',
            'contenido': '¿Qué tal?',
            'leido': true,
            'createdAt': DateTime.now().toIso8601String()
          }
        ]
      };

      // Mockeamos GET de historial y POST implícito de _markAsRead que se lanza en _init()
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(fakeResponse), 200));
      when(mockClient.post(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 200));

      // Act
      provider = ChatProvider(
        socketService: mockSocket,
        client: mockClient,
        conversationId: 'conv_1',
        contactId: 'other_user',
        currentUserId: 'my_user',
      );

      // _init() y _fetchMessages() son asíncronos. Damos un tick al microtask loop.
      await Future.delayed(Duration.zero);

      // Assert
      expect(provider.messages.length, 2);
      // El array de la API venía: [msg_old, msg_new]
      // El Provider debió invertirlo para que el UI renderice del más nuevo al más viejo
      expect(provider.messages[0].id, 'msg_new'); 
      expect(provider.messages[1].id, 'msg_old');
    });

    test('2. Envío exitoso de mensaje (Optimista -> Real)', () async {
      // Arrange: Historial inicial vacío
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'mensajes': []}), 200));
      when(mockClient.post(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 200));

      provider = ChatProvider(
        socketService: mockSocket,
        client: mockClient,
        conversationId: 'conv_1',
        contactId: 'other_user',
        currentUserId: 'my_user',
      );
      await Future.delayed(Duration.zero);
      expect(provider.messages.isEmpty, true);

      // Preparamos el mock del POST que simula la respuesta de la base de datos (MongoId real)
      final realMessage = {
        'mensaje': {
          '_id': 'msg_real_mongo_id',
          'conversacionId': 'conv_1',
          'autorId': 'my_user',
          'destinatarioId': 'other_user',
          'contenido': 'Mensaje optimista',
          'leido': false,
          'createdAt': DateTime.now().toIso8601String()
        }
      };
      
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(jsonEncode(realMessage), 201));

      // Act
      // Capturamos el Future sin hacer "await" todavía, para asomarnos al estado intermedio
      final sendFuture = provider.sendMessage('Mensaje optimista');
      
      // ESTADO OPTIMISTA (Intermedio): el mensaje está en memoria con un ID falso
      expect(provider.messages.length, 1);
      final tempId = provider.messages[0].id;
      expect(tempId.length, greaterThan(10)); // El tempId es un epoch largo, > 10 chars
      expect(provider.messages[0].contenido, 'Mensaje optimista');

      // Esperamos a que la petición termine y haga la sustitución
      await sendFuture;

      // Assert (Final): El ID falso fue reemplazado por el MongoId, sin duplicarse
      expect(provider.messages.length, 1);
      expect(provider.messages[0].id, 'msg_real_mongo_id');
      expect(provider.messages[0].contenido, 'Mensaje optimista');
    });

    test('3. Envío fallido de mensaje (Optimista -> Rollback)', () async {
      // Arrange: Historial vacío
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'mensajes': []}), 200));
      when(mockClient.post(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 200));

      provider = ChatProvider(
        socketService: mockSocket,
        client: mockClient,
        conversationId: 'conv_1',
        contactId: 'other_user',
        currentUserId: 'my_user',
      );
      await Future.delayed(Duration.zero);

      // Preparamos el mock del POST para que tire un error 500 (Ej: Backend caído)
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Internal Server Error', 500));

      // Act
      final sendFuture = provider.sendMessage('Mensaje fallido');
      
      // ESTADO OPTIMISTA
      expect(provider.messages.length, 1);
      
      // Esperamos a que el servidor "falle"
      await sendFuture;

      // Assert: ¡Rollback! El provider detectó el error y limpió el UI de mentiras
      expect(provider.messages.isEmpty, true);
    });
  });
}
