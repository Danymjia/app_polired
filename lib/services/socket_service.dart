import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../config/constants.dart';

enum SocketConnectionPhase { disconnected, connecting, connected, reconnecting }

/// Responsabilidad principal:
/// Wrapper en formato Singleton de `PusherChannelsFlutter` para el manejo de WebSocket en tiempo real.
///
/// Flujo dentro de la app:
/// Inicializado por `AuthProvider` al hacer login exitoso. Mantiene una conexión persistente autenticada al canal `private-user-$uid`. Otros Providers (`ChatProvider`, `NotificationProvider`) se suscriben usando el patrón Event Emitter (`on()`, `off()`).
///
/// Dependencias críticas:
/// - `pusher_channels_flutter`.
/// - `AppConstants.socketUrl` (Endpoint de autenticación).
///
/// Side Effects:
/// - Sockets: Abre una conexión TCP bidireccional asíncrona persistente (hilo nativo en Android/iOS).
///
/// Recordatorios técnicos y CQRS:
/// - Fugas de Memoria Potenciales: Usa un diccionario `_eventListeners` manual en memoria. Es imperativo que todo consumidor de eventos llame a `off()` en el método `dispose()` de su widget o provider, de lo contrario habrá callbacks fantasma (Ghost Listeners).
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  String? _token;
  String? _userId;

  final ValueNotifier<SocketConnectionPhase> connectionPhase = ValueNotifier(
    SocketConnectionPhase.disconnected,
  );

  bool get isConnected =>
      connectionPhase.value == SocketConnectionPhase.connected;

  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  void _setPhase(SocketConnectionPhase p) {
    if (connectionPhase.value != p) {
      connectionPhase.value = p;
    }
  }

  bool _isPusherConnectedFlag = false;

  Future<void> connect(String jwtToken, String userId) async {
    if (jwtToken.isEmpty) return;
    if (_token == jwtToken && isConnected) return;

    await disconnectInternal(clearPhase: false);
    _token = jwtToken;
    _userId = userId;
    _setPhase(SocketConnectionPhase.connecting);

    try {

      await pusher.init(
        apiKey: "278aa167ddc365cd37a2",
        cluster: "us2",
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        authEndpoint: "${AppConstants.socketUrl}/api/pusher/auth?token=$_token",
        authParams: {
          'headers': {'Authorization': 'Bearer $_token'},
        },
      );
      
      await pusher.connect();

      _isPusherConnectedFlag = true;
    } catch (e) {
      debugPrint("Pusher connect error: $e");
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    if (currentState == "CONNECTED") {
      _setPhase(SocketConnectionPhase.connected);
      final uid = _userId;
      if (uid != null && uid.isNotEmpty) {
        pusher
            .subscribe(channelName: "private-user-$uid")
            .then((_) {
            })
            .catchError((e) {
            });
            
        // TEMPORAL - solo para diagnóstico
        pusher
            .subscribe(channelName: "test-channel")
            .then((_) {
            })
            .catchError((e) {
            });
      } else {
      }
    } else if (currentState == "CONNECTING") {
      _setPhase(SocketConnectionPhase.connecting);
    } else if (currentState == "DISCONNECTED") {
      _setPhase(SocketConnectionPhase.disconnected);
    } else if (currentState == "RECONNECTING") {
      _setPhase(SocketConnectionPhase.reconnecting);
    }
  }

  void _onError(String message, int? code, dynamic e) {
    if (!isConnected &&
        connectionPhase.value != SocketConnectionPhase.reconnecting) {
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }

  void _onEvent(PusherEvent event) {
    final eventName = event.eventName;
    dynamic data = event.data;

    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    final listeners = _eventListeners[eventName];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(data);
      }
    }
  }

  void on(String event, void Function(dynamic) handler) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    // Evitar duplicar el listener si un provider re-registra
    if (!_eventListeners[event]!.contains(handler)) {
      _eventListeners[event]!.add(handler);
    }
  }

  void off(String event, [void Function(dynamic)? handler]) {

    if (handler != null) {
      _eventListeners[event]?.remove(handler);
      if (_eventListeners[event]?.isEmpty == true) {
        _eventListeners.remove(event);
      }
    } else {
      _eventListeners.remove(event);
    }
  }

  Future<void> disconnect() async {
    await disconnectInternal(clearPhase: true);
  }

  Future<void> disconnectInternal({required bool clearPhase}) async {
    if (_isPusherConnectedFlag) {
      try {
        await pusher.disconnect();
      } catch (_) {
      } finally {
        _isPusherConnectedFlag = false;
      }
    }
    _token = null;
    _userId = null;

    if (clearPhase) {
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }

  // Nuevo método explícito para limpiar todo (Logout)
  void clearAllListeners() {
    _eventListeners.clear();
  }
}
