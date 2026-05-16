import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/constants.dart';

/// Fases de conexión expuestas a la UI (mensajes, banners, etc.).
enum SocketConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket Socket.IO alineado con el handshake JWT del backend.
///
/// El servidor valida `handshake.auth.token` o el header `Authorization`.
/// No se emiten eventos de cliente que el backend no defina.
class SocketService {
  io.Socket? _socket;
  String? _token;
  bool _managerHooks = false;

  final ValueNotifier<SocketConnectionPhase> connectionPhase =
      ValueNotifier(SocketConnectionPhase.disconnected);

  io.Socket? get socket => _socket;

  bool get isConnected =>
      connectionPhase.value == SocketConnectionPhase.connected;

  void _setPhase(SocketConnectionPhase p) {
    if (connectionPhase.value != p) {
      connectionPhase.value = p;
    }
  }

  void _attachManagerHooks() {
    final s = _socket;
    if (s == null || _managerHooks) return;
    _managerHooks = true;
    s.io.on('reconnect_attempt', (_) {
      _setPhase(SocketConnectionPhase.reconnecting);
    });
    s.io.on('reconnect', (_) {
      _setPhase(SocketConnectionPhase.connected);
    });
    s.io.on('reconnect_failed', (_) {
      _setPhase(SocketConnectionPhase.disconnected);
    });
  }

  void _detachManagerHooks() {
    final s = _socket;
    if (s == null || !_managerHooks) return;
    s.io.off('reconnect_attempt');
    s.io.off('reconnect');
    s.io.off('reconnect_failed');
    _managerHooks = false;
  }

  /// Conecta usando el JWT del estudiante (mismo token que las peticiones HTTP).
  void connect(String jwtToken) {
    if (jwtToken.isEmpty) return;

    if (_socket != null && _token == jwtToken && isConnected) {
      return;
    }

    disconnectInternal(clearPhase: false);

    _token = jwtToken;
    _setPhase(SocketConnectionPhase.connecting);

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth({'token': jwtToken})
          .disableAutoConnect()
          .build(),
    );

    _attachManagerHooks();

    _socket!.onConnect((_) {
      _setPhase(SocketConnectionPhase.connected);
    });

    _socket!.onConnectError((_) {
      if (connectionPhase.value != SocketConnectionPhase.reconnecting) {
        _setPhase(SocketConnectionPhase.disconnected);
      }
    });

    _socket!.onDisconnect((_) {
      if (_socket != null && _socket!.connected) return;
      if (connectionPhase.value != SocketConnectionPhase.reconnecting) {
        _setPhase(SocketConnectionPhase.disconnected);
      }
    });

    _socket!.onError((_) {
      if (!isConnected && connectionPhase.value != SocketConnectionPhase.reconnecting) {
        _setPhase(SocketConnectionPhase.disconnected);
      }
    });

    _socket!.connect();
  }

  /// Libera el socket y deja la fase en [disconnected] (p. ej. logout).
  void disconnect() {
    disconnectInternal(clearPhase: true);
  }

  void disconnectInternal({required bool clearPhase}) {
    _detachManagerHooks();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
    if (clearPhase) {
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}
