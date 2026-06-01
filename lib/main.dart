import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/global_feed_provider.dart';
import 'providers/messages_inbox_provider.dart';
import 'providers/network_provider.dart';
import 'providers/explore_networks_provider.dart';
import 'providers/network_profile_provider.dart';
import 'providers/map_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/post_store_provider.dart';
import 'providers/explore_users_provider.dart';
import 'services/read_model_cache_service.dart';
import 'services/navigation_bus.dart';
import 'services/navigation_service.dart';
import 'providers/public_profile_provider.dart';
import 'providers/my_profile_feed_provider.dart';
import 'repositories/conversations_repository.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';
import 'services/post_service.dart';
import 'services/socket_service.dart';
import 'services/storage_service.dart';
import 'services/explore_user_service.dart';
import 'services/public_profile_service.dart';
import 'services/command_bus.dart';
import 'services/handlers/post_command_handlers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Responsabilidad principal:
/// Punto de entrada de la aplicación. Inicializa servicios base, configura el entorno,
/// y ensambla el árbol de dependencias global utilizando MultiProvider.
///
/// Flujo dentro de la app:
/// Es el primer archivo ejecutado. Construye e inyecta los repositorios, servicios y
/// command handlers (CQRS), proveyendo el estado global a `PoliredApp`.
///
/// Dependencias críticas:
/// - flutter_dotenv
/// - mapbox_maps_flutter
/// - shared_preferences (vía StorageService)
/// - Provider (MultiProvider, ChangeNotifierProxyProvider)
///
/// Side Effects:
/// - Carga variables de entorno (I/O).
/// - Inicializa token global de Mapbox.
/// - Persiste configuración inicial en memoria (StorageService).
/// - Configura orientación forzada y estilos de barra de estado en SystemChrome.
///
/// Recordatorios técnicos y CQRS:
/// - Fuerte acoplamiento en la inyección de dependencias estáticas (CQRS Handlers se registran aquí).
/// - `PostStoreProvider` es el núcleo reactivo; se inyecta ANTES que los ProxyProviders para evitar nulos y garantizar consistencia de estado.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Inicializar Mapbox globalmente para evitar pantalla negra en v2.x+
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '');

  // Inicializar almacenamiento local
  await StorageService.init();

  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  // ─── Árbol de dependencias ────────────────────────────────────────────────
  final apiService = ApiService();
  final socketService = SocketService();
  final authService = AuthService(apiService);
  final networkService = NetworkService(apiService);
  final postService = PostService(apiService);
  final notificationService = NotificationService(apiService);
  final exploreUserService = ExploreUserService(apiService);
  final publicProfileService = PublicProfileService(apiService);
  final conversationsRepository = ConversationsRepository(apiService);

  // ─── Inicialización de CQRS Core ──────────────────────────────────────────
  final postStoreProvider = PostStoreProvider();
  final commandBus = CommandBus();
  final navigationBus = NavigationBus();
  
  NavigationService.instance.init(navigationBus);
  
  // Registro de Handlers
  commandBus.registerHandler(CreatePostCommandHandler(postService, postStoreProvider, navigationBus));
  commandBus.registerHandler(ToggleLikeCommandHandler(postService, postStoreProvider));
  commandBus.registerHandler(ToggleSaveCommandHandler(postService, postStoreProvider));
  commandBus.registerHandler(DeletePostCommandHandler(postService, postStoreProvider));
  commandBus.registerHandler(InitializeSocialStateCommandHandler(postService, postStoreProvider));

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<PostService>.value(value: postService),
        Provider<SocketService>.value(value: socketService),
        Provider<NetworkService>.value(value: networkService),
        Provider<ExploreUserService>.value(value: exploreUserService),
        Provider<PublicProfileService>.value(value: publicProfileService),
        Provider<ConversationsRepository>.value(value: conversationsRepository),
        Provider<CommandBus>.value(value: commandBus),
        Provider<NavigationBus>.value(value: navigationBus),
        Provider<ReadModelCacheService>(
          create: (_) => ReadModelCacheService(),
          dispose: (_, service) => service.disposeAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExploreNetworksProvider(networkService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExploreUsersProvider(exploreUserService),
        ),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        // PostStoreProvider must be declared BEFORE any ProxyProvider that depends on it
        ChangeNotifierProxyProvider<AuthProvider, PostStoreProvider>(
          create: (_) => postStoreProvider,
          update: (_, auth, store) {
            if (!auth.isAuthenticated) {
              store?.clear();
            }
            return store!;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, PostStoreProvider, NetworkProvider>(
          create: (context) => NetworkProvider(networkService, postService, context.read<PostStoreProvider>()),
          update: (_, auth, store, previous) {
            final provider = previous ?? NetworkProvider(networkService, postService, store);
            if (auth.isAuthenticated && auth.user != null) {
              if (!provider.hasLoadedOnce) {
                provider.setLoadedOnce();
                provider.loadStudentNetworks();
                provider.fetchRedesDelEstudiante();
              }
            } else {
              provider.clear();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, NetworkProfileProvider>(
          create: (context) => NetworkProfileProvider(networkService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? NetworkProfileProvider(networkService, store),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, PostStoreProvider, GlobalFeedProvider>(
          create: (context) => GlobalFeedProvider(postService, context.read<PostStoreProvider>()),
          update: (_, auth, store, previous) {
            final provider = previous ?? GlobalFeedProvider(postService, store);
            if (auth.isAuthenticated && auth.user != null) {
              if (!provider.hasLoadedOnce) {
                provider.setLoadedOnce();
                provider.loadInitial();
              }
            } else {
              provider.clear();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, PublicProfileProvider>(
          create: (context) => PublicProfileProvider(publicProfileService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? PublicProfileProvider(publicProfileService, store),
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, MyProfileFeedProvider>(
          create: (context) => MyProfileFeedProvider(publicProfileService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? MyProfileFeedProvider(publicProfileService, store),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(notificationService, context.read<SocketService>()),
          update: (context, auth, previous) {
            final provider = previous ?? NotificationProvider(notificationService, context.read<SocketService>());
            provider.onAuthChanged(auth.user);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, MessagesInboxProvider>(
          create: (context) => MessagesInboxProvider(
            conversationsRepository: context.read<ConversationsRepository>(),
            networkService: context.read<NetworkService>(),
            socketService: context.read<SocketService>(),
          ),
          update: (context, auth, previous) {
            final inbox = previous ??
                MessagesInboxProvider(
                  conversationsRepository: context.read<ConversationsRepository>(),
                  networkService: context.read<NetworkService>(),
                  socketService: context.read<SocketService>(),
                );
            if (auth.isLoading) {
              return inbox;
            }
            if (auth.isAuthenticated && auth.user != null) {
              inbox.onAuthChanged(auth.user);
            } else {
              inbox.onAuthChanged(null);
            }
            return inbox;
          },
        ),
      ],
      child: const PoliredApp(),
    ),
  );
}

class PoliredApp extends StatelessWidget {
  const PoliredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Polired',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
