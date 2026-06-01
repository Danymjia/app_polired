import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/feed_context.dart';
import '../models/events/post_event.dart';
import 'navigation_bus.dart';

/// Responsabilidad principal:
/// Controlador de la Interfaz Gráfica sin contexto. Manipula el Scroll y el Foco visual de los Feeds sin acoplar los Providers (o Handlers) al árbol de Widgets de Flutter.
///
/// Flujo dentro de la app:
/// Los widgets (ej. listas) registran sus `ScrollController` aquí. Cuando la capa de dominio emite un `FocusPostEvent` por el bus, este servicio ejecuta `Scrollable.ensureVisible` para hacer auto-scroll hacia el nuevo post.
///
/// Dependencias críticas:
/// - `NavigationBus` (Stream de eventos pub/sub).
///
/// Side Effects:
/// - Mutación de UI: Controla físicamente animaciones y posiciones en pantalla.
///
/// Recordatorios técnicos y CQRS:
/// - Fugas de Memoria Severas: Mantener referencias globales (`_controllers`, `postKeys`) a los elementos visuales es peligroso. Si un Widget olvida llamar a `unregister()` en su método `dispose()`, causará Memory Leaks e inconsistencias fatales al tratar de animar componentes desmontados.
class NavigationService {
  NavigationService._();
  static final instance = NavigationService._();

  final Map<FeedContext, ScrollController> _controllers = {};
  final Map<String, GlobalKey> postKeys = {};
  late StreamSubscription<NavigationEvent> _subscription;

  void init(NavigationBus bus) {
    _subscription = bus.stream.listen(_handleNavigationEvent);
  }

  /// Registra un GlobalKey para un post específico
  void registerPostKey(String postId, GlobalKey key) {
    postKeys[postId] = key;
  }

  /// Remueve un GlobalKey para evitar memory leaks
  void unregisterPostKey(String postId) {
    postKeys.remove(postId);
  }

  /// Llamar desde initState() del widget del feed
  void register(FeedContext context, ScrollController controller) {
    _controllers[context] = controller;
  }

  /// Llamar desde dispose() del widget del feed — OBLIGATORIO
  void unregister(FeedContext context) {
    _controllers.remove(context);
  }

  void _handleNavigationEvent(NavigationEvent event) async {
    if (event is FocusPostEvent) {
      // Damos tiempo a que MainLayoutScreen (u otra UI) cambie el tab 
      // y monte el nuevo widget en el árbol antes de evaluar los controladores
      await Future.delayed(const Duration(milliseconds: 150));

      ScrollController? controller = _controllers[event.context];
      
      // Fallback: si es Home, el controlador está registrado como home() sin ID
      if (controller == null && event.context.type == ContextType.home) {
        final matches = _controllers.entries.where((e) => e.key.type == ContextType.home);
        if (matches.isNotEmpty) {
          controller = matches.first.value;
        }
      }

      if (controller == null || !controller.hasClients) return;

      // Intentar encontrar el widget exacto usando GlobalKey
      final key = postKeys[event.postId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.1, // Un poco por debajo del borde superior
        );
      } else {
        // Fallback: al tope
        controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void dispose() {
    _subscription.cancel();
    _controllers.clear();
  }
}
