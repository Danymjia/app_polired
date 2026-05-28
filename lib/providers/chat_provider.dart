import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/message_model.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final SocketService _socketService;
  final String _conversationId;
  final String _contactId;
  final String _currentUserId;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  final int _limit = 50;
  String? _errorMessage;

  List<MessageModel> _messages = [];
  bool _isContactOnline = false;
  final void Function(String contenido, String autorId, DateTime createdAt)? onMessageSent;

  ChatProvider({
    required SocketService socketService,
    required String conversationId,
    required String contactId,
    required String currentUserId,
    this.onMessageSent,
  })  : _socketService = socketService,
        _conversationId = conversationId,
        _contactId = contactId,
        _currentUserId = currentUserId {
    _init();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isContactOnline => _isContactOnline;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _socketService.subscribeToConversation(_conversationId);
    _setupSocketListeners();
    await _fetchMessages(refresh: true);
    await _markAsRead();

    _isLoading = false;
    notifyListeners();
  }

  void _setupSocketListeners() {
    _socketService.on('nuevo_mensaje', _onNuevoMensaje);
    _socketService.on('nuevo_mensaje_local', _onNuevoMensaje);
    _socketService.on('mensajes_leidos', _onMensajesLeidos);
    
    // Pusher presence events
    _socketService.on('pusher:subscription_succeeded', _onPresenceSucceeded);
    _socketService.on('pusher:member_added', _onPresenceAdded);
    _socketService.on('pusher:member_removed', _onPresenceRemoved);
  }

  void _removeSocketListeners() {
    _socketService.off('nuevo_mensaje');
    _socketService.off('nuevo_mensaje_local');
    _socketService.off('mensajes_leidos');
    _socketService.off('pusher:subscription_succeeded');
    _socketService.off('pusher:member_added');
    _socketService.off('pusher:member_removed');
  }

  void _onNuevoMensaje(dynamic payload) {
    if (payload == null) return;
    try {
      final map = payload is Map ? payload : jsonDecode(payload.toString());
      final msgMap = map['mensaje'];
      if (msgMap == null) return;
      if (msgMap['conversacionId'] != _conversationId) return;

      final newMsg = MessageModel.fromJson(Map<String, dynamic>.from(msgMap));
      
      // Si ya existe el real (ej. por respuesta HTTP más rápida), ignorar
      if (_messages.any((m) => m.id == newMsg.id)) return;

      // Buscar el optimista
      final tempIndex = _messages.indexWhere((m) => 
        m.id.length > 10 && // los ids de mongo son de 24 chars, el temporal es un timestamp
        m.autorId == newMsg.autorId && 
        m.contenido == newMsg.contenido
      );

      if (tempIndex != -1) {
        _messages[tempIndex] = newMsg;
      } else {
        _messages.insert(0, newMsg);
      }
      
      if (newMsg.autorId != _currentUserId) {
        _markAsRead();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error parseando nuevo_mensaje en ChatProvider: $e");
    }
  }

  void _onMensajesLeidos(dynamic payload) {
    if (payload == null) return;
    try {
      final map = payload is Map ? payload : jsonDecode(payload.toString());
      if (map['conversacionId'] == _conversationId) {
        // Marcar todos los enviados por mi como leidos
        _messages = _messages.map((m) {
          if (m.autorId == _currentUserId && !m.leido) {
            return m.copyWith(leido: true);
          }
          return m;
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onPresenceSucceeded(dynamic payload) {
    if (payload == null) return;
    try {
      final data = payload is Map ? payload : jsonDecode(payload.toString());
      final membersMap = data['presence']?['hash'] as Map?;
      if (membersMap != null) {
        _isContactOnline = membersMap.containsKey(_contactId);
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onPresenceAdded(dynamic payload) {
    if (payload == null) return;
    try {
      final data = payload is Map ? payload : jsonDecode(payload.toString());
      if (data['user_id'] == _contactId) {
        _isContactOnline = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onPresenceRemoved(dynamic payload) {
    if (payload == null) return;
    try {
      final data = payload is Map ? payload : jsonDecode(payload.toString());
      if (data['user_id'] == _contactId) {
        _isContactOnline = false;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _hasMore = true;
      _messages.clear();
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final token = StorageService.getToken() ?? '';
      final url = Uri.parse('${AppConstants.baseUrl}/conversacion/$_conversationId?page=$_page&limit=$_limit');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['mensajes'] as List?;
        if (list != null) {
          final newMessages = list.map((m) => MessageModel.fromJson(m)).toList();
          if (newMessages.length < _limit) {
            _hasMore = false;
          }
          
          // La lista de la API se devuelve en orden cronológico ascendente (el más viejo primero).
          // Necesitamos invertirla para el ListView.builder con reverse: true.
          // El primer elemento debe ser el mensaje más reciente.
          final reversedMessages = newMessages.reversed.toList();
          
          if (refresh) {
            _messages = reversedMessages;
          } else {
            _messages.addAll(reversedMessages);
          }
          _page++;
        }
      } else {
        _errorMessage = 'Error al cargar historial';
      }
    } catch (e) {
      _errorMessage = 'Error de red';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    await _fetchMessages(refresh: false);
  }

  Future<void> _markAsRead() async {
    try {
      final token = StorageService.getToken() ?? '';
      final url = Uri.parse('${AppConstants.baseUrl}/$_conversationId/leidos');
      await http.post(url, headers: {'Authorization': 'Bearer $token'});
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // Crear el objeto de forma optimista
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optMsg = MessageModel(
      id: tempId,
      conversacionId: _conversationId,
      autorId: _currentUserId,
      destinatarioId: _contactId,
      contenido: text.trim(),
      leido: false,
      createdAt: DateTime.now(),
    );
    
    _messages.insert(0, optMsg);
    notifyListeners();

    try {
      final token = StorageService.getToken() ?? '';
      final url = Uri.parse('${AppConstants.baseUrl}/send');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'destinatarioId': _contactId,
          'contenido': text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final realMsg = MessageModel.fromJson(data['mensaje']);
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          _messages[idx] = realMsg;
        } else {
          // Si por alguna razón Pusher no lo agregó y el optimista desapareció
          _messages.insert(0, realMsg);
        }
        onMessageSent?.call(realMsg.contenido, realMsg.autorId, realMsg.createdAt);
        notifyListeners();
      } else {
        _messages.removeWhere((m) => m.id == tempId);
        notifyListeners();
      }
      
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _removeSocketListeners();
    _socketService.unsubscribeFromConversation(_conversationId);
    super.dispose();
  }
}
