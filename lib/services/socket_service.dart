import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/constants.dart';

/// Servicio de WebSocket usando socket.io.
/// Se inicializa al arrancar la app y permite emitir eventos.
/// Las funcionalidades realtime completas se implementarán en fases posteriores.
class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Conectar al servidor de sockets con el ID del estudiante.
  void connect(String estudianteId) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      // Registrar el usuario en el mapa de conectados del servidor
      _socket!.emit('usuario:conectar', estudianteId);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onError((err) {
      _isConnected = false;
    });

    _socket!.connect();
  }

  /// Desconectar del servidor.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Emitir un evento al servidor.
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Escuchar un evento del servidor.
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remover un listener.
  void off(String event) {
    _socket?.off(event);
  }
}
