import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'explore/explore_screen.dart';
import 'home/home_screen.dart';
import 'messages/messages_screen.dart';
import 'post/add_post_screen.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../models/events/post_event.dart';
import '../../services/navigation_bus.dart';
import '../../models/feed_context.dart';
import '../../providers/network_provider.dart';
import 'profile/profile_screen.dart';

/// Responsabilidad principal:
/// Contenedor raíz (Layout) para la navegación principal basada en pestañas (BottomNavigationBar).
///
/// Flujo dentro de la app:
/// Mantiene un `IndexedStack` para preservar el estado de las 5 pantallas principales y no reconstruirlas al cambiar de tab. Escucha eventos del `NavigationBus` para forzar cambios de pestaña programáticos.
///
/// Dependencias críticas:
/// - `NavigationBus` (Para FocusPostEvent).
/// - `NetworkProvider` (Para pre-seleccionar comunidades desde notificaciones/eventos).
///
/// Side Effects:
/// - Preservación de Estado: Mantiene vivos todos los sub-árboles de widgets (Home, Chat, Perfil) simultáneamente en RAM.
///
/// Recordatorios técnicos y CQRS:
/// - Anti-patrón de GlobalKey: El uso de `_homeKey` y `_exploreKey` para castear de forma dinámica (`as dynamic`) y forzar métodos (`scrollToTop`) es frágil. Todos los scrolls globales deben manejarse con el `NavigationService`.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  // GlobalKey para Explore (luego lo agregaremos en ExploreScreen)
  final GlobalKey _exploreKey = GlobalKey();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    ExploreScreen(key: _exploreKey),
    const AddPostScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  StreamSubscription? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bus = context.read<NavigationBus>();
      _navigationSubscription = bus.stream.listen((event) {
        if (event is FocusPostEvent && mounted) {
          int targetIndex = _currentIndex;
          if (event.context.type == ContextType.home) {
            targetIndex = 0;
            final communityId = event.context.communityId;
            if (communityId != null) {
              context.read<NetworkProvider>().selectNetworkById(communityId);
            }
          } else if (event.context.type == ContextType.exploreTab || event.context.type == ContextType.exploreGlobal) {
            targetIndex = 1;
          } else if (event.context.type == ContextType.profile) {
            targetIndex = 4;
          }
          if (targetIndex != _currentIndex) {
            setState(() {
              _currentIndex = targetIndex;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Needed for transparent/blur bottom nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              border: const Border(
                top: BorderSide(
                  color: Colors.black12,
                  width: 1.0,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen()));
                  return;
                }
                if (_currentIndex == index) {
                  if (index == 0) {
                    _homeKey.currentState?.scrollToTop();
                  } else if (index == 1) {
                    // LLamaremos el método a través del cast si ExploreScreenState lo expone
                    final exploreState = _exploreKey.currentState;
                    if (exploreState != null) {
                      // ignore: avoid_dynamic_calls
                      (exploreState as dynamic).scrollToTop();
                    }
                  }
                  return;
                }
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: const Color(0xFF1E3A8A), // Azul oscuro
              unselectedItemColor: AppTheme.onSurfaceVariant,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 28),
                  activeIcon: Icon(Icons.home, size: 28),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search, size: 28),
                  label: 'Explorar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined, size: 28),
                  activeIcon: Icon(Icons.add_box, size: 28),
                  label: 'Publicar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline, size: 28),
                  activeIcon: Icon(Icons.chat_bubble, size: 28),
                  label: 'Mensajes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 28),
                  activeIcon: Icon(Icons.person, size: 28),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
