# Evidencia de Pruebas - PoliRed (App Móvil)

Este documento centraliza los resultados y evidencias de las fases de Testing (Unitarias y Widgets), asegurando la calidad de las capas de Servicio, Proveedores de Estado, Manejadores de Comandos (CQRS) y UI.

## [Capa: Service] AuthService
**Archivo:** `test/services/auth_service_test.dart`
**Qué valida:** La correcta inyección y consumo del cliente HTTP para autenticación, validando el mapeo de respuestas 200 OK hacia la extracción y persistencia de tokens de sesión, y el manejo de excepciones HTTP 401.
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/services/auth_service_test.dart`
**Resultado:** All tests passed! (3 tests)

## [Capa: Service] NetworkService
**Archivo:** `test/services/network_service_test.dart`
**Qué valida:** La correcta obtención de las listas de redes (comunidades) desde la API, y el paso de parámetros correcto al interactuar con las rutas de unirse y salir de una red (enviando el `redId` adecuado).
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/services/network_service_test.dart`
**Resultado:** All tests passed! (3 tests)

## [Capa: Provider] ExploreNetworksProvider
**Archivo:** `test/providers/explore_networks_provider_test.dart`
**Qué valida:** La máquina de estados del provider (`ExploreNetworksStatus`). Garantiza que el estado inicial mute correctamente a `success` al recibir la información de redes del servicio y notifique a la vista los datos actualizados.
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/providers/explore_networks_provider_test.dart`
**Resultado:** All tests passed! (1 test)

## [Capa: Handler] PostCommandHandlers (CQRS)
**Archivo:** `test/services/handlers/post_command_handlers_test.dart`
**Qué valida:** El ciclo completo de Optimistic UI Updates. Verifica que al procesar comandos de borrado o creación, el Handler modifique el estado local (`PostStoreProvider`), lance la petición HTTP al servicio, y en caso de rechazo del backend (403), revierta estrictamente el estado original garantizando consistencia (orden preciso del RollbackEvent).
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/services/handlers/post_command_handlers_test.dart`
**Resultado:** All tests passed! (3 tests)

## [Capa: Provider] NotificationProvider
**Archivo:** `test/providers/notification_provider_test.dart`
**Qué valida:** El acoplamiento con `SocketService` para recibir notificaciones en tiempo real, validando la subscripción correcta al evento `nueva_notificacion` y el parseo del payload entrante hacia el estado observable de la app (incremento de badges).
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/providers/notification_provider_test.dart`
**Resultado:** All tests passed! (2 tests)

## [Capa: Provider] MessagesInboxProvider
**Archivo:** `test/providers/messages_inbox_provider_test.dart`
**Qué valida:** La inicialización de los mensajes y su integración con `SocketService`. Verifica que al recibir un `nuevo_mensaje` por el socket, la conversación afectada escale automáticamente a la parte superior de la lista (índice 0) de la bandeja de entrada.
**Código relevante:**
```dart
    test('2. reordenamiento de bandeja por evento de socket (nuevo_mensaje)', () async {
      // [Inicialización y carga previa...]
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
```
**Comando para reproducir:** `flutter test test/providers/messages_inbox_provider_test.dart`
**Resultado:** All tests passed! (2 tests)

## [Capa: Provider] ChatProvider
**Archivo:** `test/providers/chat_provider_test.dart`
**Qué valida:** El flujo de envío de mensajes optimista, el reemplazo del ID temporal generado localmente por el MongoId real tras recibir respuesta exitosa (201) de la API, y el manejo de historial inicial (invirtiendo el orden cronológico para renderizado UI de tipo chat).
**Código relevante:**
```dart
    test('2. Envío exitoso de mensaje (Optimista -> Real)', () async {
      // [Mockeo de estado inicial...]
      
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
```
**Comando para reproducir:** `flutter test test/providers/chat_provider_test.dart`
**Resultado:** All tests passed! (3 tests)

## [Capa: Widget] LoginScreen
**Archivo:** `test/screens/login_screen_test.dart`
**Qué valida:** El comportamiento nativo del `Form` en Flutter; asegura que sin datos válidos, los validadores locales muestren explícitamente y al pie de la letra los errores exigidos, previniendo disparar peticiones al `AuthService`.
**Código relevante:**
```dart
  testWidgets('Muestra error si se intenta iniciar sesión con campos vacíos', (WidgetTester tester) async {
    // Arrange: Montamos el widget
    await tester.pumpWidget(createWidgetUnderTest());

    // Aseguramos que la animación inicial (FadeTransition) concluya
    await tester.pumpAndSettle();

    // Verificamos que los textos de error NO existen inicialmente
    expect(find.text('El correo es obligatorio'), findsNothing);
    expect(find.text('La contraseña es obligatoria'), findsNothing);

    // Act: Hacemos tap en el botón de login sin llenar los campos
    // Usamos find.text para localizar el PrimaryButton o el texto en su interior
    await tester.tap(find.text('Iniciar sesión'));
    
    // Disparamos un frame para que los errores del FormState se rendericen
    await tester.pumpAndSettle();

    // Assert: Verificamos los strings literales exactos
    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });
```
**Comando para reproducir:** `flutter test test/screens/login_screen_test.dart`
**Resultado:** All tests passed! (1 test)

## [Capa: Widget] ProfileScreen
**Archivo:** `test/screens/profile_screen_test.dart`
**Qué valida:** La reactividad del montaje del componente con múltiples Providers acoplados (Auth, Network, MyProfileFeed, PostStore, Socket) y cómo la ejecución asíncrona de `addPostFrameCallback` interactúa exitosamente consumiendo los getters generados por el mock, previniendo errores de estado como variables `isLoadingMoreFeed` nulas.
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/screens/profile_screen_test.dart`
**Resultado:** All tests passed! (1 test)

## [Capa: Widget] PostCard
**Archivo:** `test/widgets/post_card_test.dart`
**Qué valida:** La reactividad completa en un entorno CQRS. Verifica que la mutación de estado centralizada (en `PostStoreProvider`) gatilla la reevaluación estricta de un `context.select` y permite sobrepasar la animación de un `AnimatedSwitcher` para cambiar visualmente el ícono del widget de "me gusta".
**Código relevante:**
```dart
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
```
**Comando para reproducir:** `flutter test test/widgets/post_card_test.dart`
**Resultado:** All tests passed! (1 test)

---

## Hallazgos de QA y Mejoras de Arquitectura (Refactoring)

Durante el ciclo de desarrollo de las pruebas automatizadas, se detectaron y resolvieron limitaciones en el diseño inicial del código de la App:

1. **Inyección Dinámica de Dependencias (`http.Client`) en `ChatProvider`:**
   * **Hallazgo:** El provider consumía la API de chat realizando instancias locales e inmutables del cliente HTTP por debajo de la interfaz, lo cual hacía imposible emular interacciones de red e imposibilitaba el uso de un mock robusto en los tests unitarios.
   * **Mejora/Solución:** Se expuso de manera transparente un inyector (mediante un parámetro con nombre requerido) hacia la instancia de la clase, aplicando los principios del patrón de Inyección de Dependencias, lo que permitió conectar Mockito correctamente simulando latencia y payload para el historial y envío optimista.

2. **Patrón de Falsificación Nativos (Fake Pattern) sobre `ChangeNotifierProvider`:**
   * **Hallazgo:** Emplear Mocks creados automáticamente por `build_runner` resultó incompatible con las suscripciones internas de Flutter para Providers (`ChangeNotifier`). La librería subyacente `Listenable` y `Provider.value` chocaban con las intercepciones de Mockito al intentar registrar y emitir notificaciones (`notifyListeners()`).
   * **Mejora/Solución:** Se descartó parcialmente el mock inyectable (`MockPostStoreProvider`) exclusivamente para testing de UI reactiva en Widgets, y se arquitectó un *Fake nativo* manual (`TestPostStoreProvider extends ChangeNotifier implements PostStoreProvider`). Esto revirtió el control absoluto de `notifyListeners()` hacia el framework de Dart, logrando así que los componentes `context.select` reciban la reevaluación genuina en cada ciclo CQRS y forzando la actualización visual.

---

## Tabla Resumen de Ejecución

| Capa | Archivo | Tests | Estado |
|---|---|---|---|
| Service | auth_service_test.dart | 3 | Aprobado |
| Service | network_service_test.dart | 3 | Aprobado |
| Provider | explore_networks_provider_test.dart | 1 | Aprobado |
| Handler (CQRS) | post_command_handlers_test.dart | 3 | Aprobado |
| Provider | notification_provider_test.dart | 2 | Aprobado |
| Provider | messages_inbox_provider_test.dart | 2 | Aprobado |
| Provider | chat_provider_test.dart | 3 | Aprobado |
| Widget | login_screen_test.dart | 1 | Aprobado |
| Widget | profile_screen_test.dart | 1 | Aprobado |
| Widget | post_card_test.dart | 1 | Aprobado |

**Total:** 20 tests, 10 archivos.