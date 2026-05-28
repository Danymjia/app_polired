import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../config/constants.dart';

enum SocketConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Servicio Singleton de PusherChannels para tiempo real.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  String? _token;
  String? _userId;

  final ValueNotifier<SocketConnectionPhase> connectionPhase =
      ValueNotifier(SocketConnectionPhase.disconnected);

  bool get isConnected => connectionPhase.value == SocketConnectionPhase.connected;

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
        authEndpoint: "${AppConstants.socketUrl}/api/pusher/auth",
        authParams: {
          'headers': {
            'Authorization': 'Bearer $_token',
          }
        },
      );

      await pusher.connect();
      _isPusherConnectedFlag = true;
      await pusher.subscribe(channelName: "private-user-$_userId");
      _setPhase(SocketConnectionPhase.connected);
    } catch (e) {
      debugPrint("Pusher connect error: $e");
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }

  Future<void> subscribeToConversation(String conversationId) async {
    if (!isConnected) return;
    try {
      await pusher.subscribe(channelName: "presence-chat-$conversationId");
    } catch (e) {
      debugPrint("Pusher subscribe error: $e");
    }
  }

  Future<void> unsubscribeFromConversation(String conversationId) async {
    if (!isConnected) return;
    try {
      await pusher.unsubscribe(channelName: "presence-chat-$conversationId");
    } catch (e) {
      debugPrint("Pusher unsubscribe error: $e");
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    if (currentState == "CONNECTED") {
      _setPhase(SocketConnectionPhase.connected);
    } else if (currentState == "CONNECTING") {
      _setPhase(SocketConnectionPhase.connecting);
    } else if (currentState == "DISCONNECTED") {
      _setPhase(SocketConnectionPhase.disconnected);
    } else if (currentState == "RECONNECTING") {
      _setPhase(SocketConnectionPhase.reconnecting);
    }
  }

  void _onError(String message, int? code, dynamic e) {
    debugPrint("Pusher error: $message code: $code");
    if (!isConnected && connectionPhase.value != SocketConnectionPhase.reconnecting) {
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
    _eventListeners[event]!.add(handler);
  }

  void off(String event) {
    _eventListeners.remove(event);
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
    _eventListeners.clear();
    if (clearPhase) {
      _setPhase(SocketConnectionPhase.disconnected);
    }
  }
}
