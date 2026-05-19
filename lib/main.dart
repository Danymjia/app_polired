import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/global_feed_provider.dart';
import 'providers/messages_inbox_provider.dart';
import 'providers/network_provider.dart';
import 'providers/community_feed_provider.dart';
import 'providers/explore_networks_provider.dart';
import 'providers/network_profile_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/post_store_provider.dart';
import 'repositories/conversations_repository.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';
import 'services/post_service.dart';
import 'services/socket_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<PostService>.value(value: postService),
        Provider<SocketService>.value(value: socketService),
        Provider<NetworkService>.value(value: networkService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExploreNetworksProvider(networkService),
        ),
        // PostStoreProvider must be declared BEFORE any ProxyProvider that depends on it
        ChangeNotifierProvider(
          create: (_) => PostStoreProvider(postService),
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, NetworkProvider>(
          create: (context) => NetworkProvider(networkService, postService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? NetworkProvider(networkService, postService, store),
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, NetworkProfileProvider>(
          create: (context) => NetworkProfileProvider(networkService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? NetworkProfileProvider(networkService, store),
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, CommunityFeedProvider>(
          create: (context) => CommunityFeedProvider(postService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? CommunityFeedProvider(postService, store),
        ),
        ChangeNotifierProxyProvider<PostStoreProvider, GlobalFeedProvider>(
          create: (context) => GlobalFeedProvider(postService, context.read<PostStoreProvider>()),
          update: (_, store, previous) => previous ?? GlobalFeedProvider(postService, store),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MessagesInboxProvider>(
          create: (context) => MessagesInboxProvider(
            conversationsRepository: ConversationsRepository(context.read<ApiService>()),
            networkService: context.read<NetworkService>(),
            socketService: context.read<SocketService>(),
          ),
          update: (context, auth, previous) {
            final inbox = previous ??
                MessagesInboxProvider(
                  conversationsRepository: ConversationsRepository(context.read<ApiService>()),
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
