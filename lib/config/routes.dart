import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/main_layout_screen.dart';
import '../screens/explore/explore_networks_screen.dart';
import '../screens/explore/network_profile_screen.dart';
import '../screens/explore/public_profile_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/map/map_screen.dart';

/// Responsabilidad principal:
/// Configuración centralizada del enrutamiento declarativo y protección de rutas mediante redirects basados en estado de sesión.
///
/// Flujo dentro de la app:
/// Consumido por el parámetro `routerConfig` de `MaterialApp.router` en `main.dart`.
///
/// Dependencias críticas:
/// - go_router
/// - Provider (consumo síncrono de AuthProvider)
///
/// Side Effects:
/// - Mutación de navegación: redirige automáticamente a `/login` si no hay sesión, o a `/complete-profile` si el perfil está incompleto.
/// - Bloqueo estricto de navegación a rutas protegidas.
///
/// Recordatorios técnicos y CQRS:
/// - El `redirect` depende críticamente del estado síncrono del `AuthProvider`; un estado inicial incorrecto causará parpadeos UI.
/// - Precaución con bucles infinitos de redirección si se anidan más reglas lógicas complejas de Auth.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoading = authProvider.isLoading;

    // Mientras carga, quedarse en splash
    if (isLoading) return '/splash';

    final isAuthenticated = authProvider.isAuthenticated;
    final isAuthRoute = ['/login', '/register', '/forgot-password', '/splash']
        .contains(state.matchedLocation);

    if (isAuthenticated) {
      final user = authProvider.user;
      if (user != null && !user.perfilCompleto) {
        // Permitir estar en welcome y complete-profile
        if (state.matchedLocation != '/complete-profile' && state.matchedLocation != '/welcome') {
          return '/complete-profile';
        }
        return null;
      }
      
      if (isAuthRoute) return '/home';
    }

    // Si no autenticado y en ruta protegida → ir a login
    if (!isAuthenticated && !isAuthRoute) return '/login';

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (ctx, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/complete-profile', builder: (ctx, state) => const CompleteProfileScreen()),
    GoRoute(path: '/welcome', builder: (ctx, state) => const WelcomeScreen()),
    GoRoute(path: '/home', builder: (ctx, state) => const MainLayoutScreen()),
    GoRoute(path: '/explore/networks', builder: (ctx, state) => const ExploreNetworksScreen()),
    GoRoute(
      path: '/explore/networks/:id',
      builder: (ctx, state) => NetworkProfileScreen(
        networkId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/explore/public-profile/:id',
      builder: (ctx, state) => PublicProfileScreen(
        userId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (ctx, state) => PostDetailScreen(
        postId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/map',
      builder: (ctx, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          conversationId: state.pathParameters['id']!,
          contactId: extra['contactId'] as String? ?? '',
          contactName: extra['contactName'] as String? ?? 'Usuario',
          contactAvatar: extra['contactAvatar'] as String?,
        );
      },
    ),
  ],
);
