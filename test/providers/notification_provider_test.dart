import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:polired/providers/notification_provider.dart';
import 'package:polired/services/notification_service.dart';
import 'package:polired/services/socket_service.dart';
import 'package:polired/providers/auth_provider.dart';
import 'package:polired/models/user_model.dart';
import 'package:polired/models/notification_model.dart';
import 'package:polired/services/api_service.dart';

@GenerateMocks([NotificationService, SocketService, AuthProvider])
import 'notification_provider_test.mocks.dart';

void main() {
  group('NotificationProvider', () {
    late NotificationProvider provider;
    late MockNotificationService mockService;
    late MockSocketService mockSocket;
    late MockAuthProvider mockAuth;

    final dummyUser = UserModel(
      id: 'user_1',
      nombre: 'Test',
      apellido: 'User',
      email: 'test@test.com',
      roles: ['estudiante'],
      perfilCompleto: true,
    );

    setUp(() {
      mockService = MockNotificationService();
      mockSocket = MockSocketService();
      mockAuth = MockAuthProvider();
      
      provider = NotificationProvider(mockService, mockSocket, mockAuth);
    });

    test('procesar un evento simulado de Pusher (nueva_notificacion)', () async {
      // Simulamos la carga inicial (vacia)
      when(mockService.getNotificaciones()).thenAnswer((_) async => ApiResult.ok([]));
      
      // Simulamos que el usuario inicia sesión. Esto debería suscribir al socket.
      provider.onAuthChanged(dummyUser);
      
      // Capturamos la función callback que el provider registra en el socket
      final verification = verify(mockSocket.on('nueva_notificacion', captureAny));
      final Function(dynamic) callback = verification.captured.first as Function(dynamic);

      // Simulamos el payload crudo que enviaría Pusher / Socket.io
      final rawEvent = {
        '_id': 'notif_1',
        'usuarioId': 'user_1',
        'tipo': 'like',
        'mensaje': 'A alguien le gustó tu post',
        'leida': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      expect(provider.notifications.length, 0);

      // Invocamos el callback inyectando el payload simulado
      callback(rawEvent);

      // Verificamos que el provider lo parseó y lo agregó a su estado
      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.id, 'notif_1');
      expect(provider.notifications.first.tipo, 'like');
    });

    test('marcar notificación como leída (Optimistic Update)', () async {
      // Estado inicial: 1 notificación no leída
      final notif = NotificationModel(
        id: 'notif_1',
        usuarioId: 'user_1',
        tipo: 'like',
        leida: false,
        createdAt: DateTime.now(),
      );
      
      when(mockService.getNotificaciones()).thenAnswer((_) async => ApiResult.ok([notif]));
      
      // Cargamos el estado inicial
      await provider.loadNotifications();
      
      expect(provider.notifications.first.leida, false);
      expect(provider.unreadCount, 1);

      // Simulamos respuesta del servidor
      when(mockService.marcarLeida('notif_1')).thenAnswer((_) async => ApiResult.ok({'msg': 'ok'}));

      // Act: marcamos como leída
      await provider.markAsRead('notif_1');

      // Assert
      expect(provider.notifications.first.leida, true);
      expect(provider.unreadCount, 0);
      
      // Verificamos que se propagó la petición a la capa de red
      verify(mockService.marcarLeida('notif_1')).called(1);
    });
  });
}
