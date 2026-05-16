import 'dart:math';

import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/network_story_model.dart';
import '../models/suggested_network_model.dart';
import '../models/user_model.dart';
import '../repositories/conversations_repository.dart';
import '../services/network_service.dart';
import '../services/socket_service.dart';
import '../utils/json_ids.dart';

/// Estado de la lista de conversaciones (HTTP).
enum InboxListStatus { loading, success, empty, error }

/// Bandera de “no leído” sin backend de recibos: mensaje entrante por socket
/// o último mensaje enviado por el otro participante.
class MessagesInboxProvider extends ChangeNotifier {
  MessagesInboxProvider({
    required ConversationsRepository conversationsRepository,
    required NetworkService networkService,
    required SocketService socketService,
  })  : _conversationsRepository = conversationsRepository,
        _networkService = networkService,
        _socketService = socketService {
    _socketService.connectionPhase.addListener(_onSocketPhase);
  }

  final ConversationsRepository _conversationsRepository;
  final NetworkService _networkService;
  final SocketService _socketService;

  String? _sessionUserId;
  InboxListStatus _listStatus = InboxListStatus.loading;
  String? _listError;
  List<ConversationModel> _conversations = [];
  List<NetworkStoryModel> _myNetworks = [];
  List<SuggestedNetworkModel> _suggestionVisible = [];
  final Set<String> _suggestionIdsShownThisSession = {};
  final Set<String> _socketUnreadConversationIds = {};
  bool _socketListeners = false;

  final Random _random = Random();

  InboxListStatus get listStatus => _listStatus;
  String? get listError => _listError;
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  List<NetworkStoryModel> get myNetworks => List.unmodifiable(_myNetworks);
  List<SuggestedNetworkModel> get suggestionVisible => List.unmodifiable(_suggestionVisible);

  SocketConnectionPhase get socketPhase => _socketService.connectionPhase.value;

  void _onSocketPhase() => notifyListeners();

  /// Llamado desde [ChangeNotifierProxyProvider] cuando cambia la sesión.
  void onAuthChanged(UserModel? user) {
    if (user == null) {
      _clearSession();
      return;
    }
    if (_sessionUserId == user.id) return;
    _sessionUserId = user.id;
    _socketUnreadConversationIds.clear();
    _loadInitialForUser();
  }

  Future<void> refresh() async {
    if (_sessionUserId == null) return;
    await _loadConversations(showLoading: false);
    await _loadMyNetworks();
    notifyListeners();
  }

  Future<void> _loadInitialForUser() async {
    _listStatus = InboxListStatus.loading;
    _listError = null;
    notifyListeners();

    await Future.wait([
      _loadMyNetworks(),
      _loadConversations(showLoading: false),
    ]);

    _pickNewSuggestionBatch();
    _ensureSocketListeners();
    notifyListeners();
  }

  Future<void> _loadMyNetworks() async {
    final r = await _networkService.getRedesEstudianteStories();
    if (r.success && r.data != null) {
      _myNetworks = r.data!;
    } else {
      _myNetworks = [];
    }
  }

  Future<void> _loadConversations({required bool showLoading}) async {
    if (showLoading) {
      _listStatus = InboxListStatus.loading;
      notifyListeners();
    }
    final result = await _conversationsRepository.fetchConversations();
    if (!result.success || result.data == null) {
      _listStatus = InboxListStatus.error;
      _listError = result.message ?? 'Error al cargar conversaciones';
      _conversations = [];
      return;
    }
    _conversations = result.data!;
    _listError = null;
    if (_conversations.isEmpty) {
      _listStatus = InboxListStatus.empty;
    } else {
      _listStatus = InboxListStatus.success;
    }
  }

  void _ensureSocketListeners() {
    if (_socketListeners) return;
    _socketListeners = true;
    void handler(dynamic data) => _handleIncomingMessageMap(data);
    _socketService.on('mensaje:nuevo', handler);
    _socketService.on('mensaje:enviado', handler);
  }

  void _removeSocketListeners() {
    if (!_socketListeners) return;
    _socketService.off('mensaje:nuevo');
    _socketService.off('mensaje:enviado');
    _socketListeners = false;
  }

  void _handleIncomingMessageMap(dynamic raw) {
    final uid = _sessionUserId;
    if (uid == null) return;
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    final convId = parseMongoId(map['conversacionId']);
    final m = map['mensaje'];
    if (convId == null || convId.isEmpty || m is! Map) return;
    final mm = Map<String, dynamic>.from(m);
    final content = mm['contenido'] as String? ?? '';
    final createdAt = parseDate(mm['createdAt']) ?? DateTime.now();
    String? autorId;
    final autor = mm['autor'];
    if (autor is Map) {
      autorId = parseMongoId(autor['_id']);
    }
    autorId ??= parseMongoId(mm['autor']);

    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx < 0) {
      _refreshConversationsInBackground();
      return;
    }

    final existing = _conversations[idx];
    final updated = existing.copyWith(
      ultimoMensaje: UltimoMensajeModel(
        contenido: content,
        autorId: autorId,
        fecha: createdAt,
      ),
      ultimaActividad: createdAt,
    );
    final copy = List<ConversationModel>.from(_conversations);
    copy.removeAt(idx);
    copy.insert(0, updated);
    _conversations = copy;

    if (autorId != null && autorId != uid) {
      _socketUnreadConversationIds.add(convId);
    }

    if (_listStatus == InboxListStatus.empty && _conversations.isNotEmpty) {
      _listStatus = InboxListStatus.success;
    }
    notifyListeners();
  }

  Future<void> _refreshConversationsInBackground() async {
    final result = await _conversationsRepository.fetchConversations();
    if (result.success && result.data != null) {
      _conversations = result.data!;
      if (_conversations.isEmpty) {
        _listStatus = InboxListStatus.empty;
      } else {
        _listStatus = InboxListStatus.success;
      }
      notifyListeners();
    }
  }

  /// Descarta una sugerencia (X). Si ya no queda ninguna, se elige un nuevo lote.
  void dismissSuggestion(String redId) {
    _suggestionVisible = _suggestionVisible.where((e) => e.id != redId).toList();
    if (_suggestionVisible.isEmpty) {
      _pickNewSuggestionBatch();
    }
    notifyListeners();
  }

  /// Seguir red desde sugerencias; usa POST /estudiantes/unirse/red.
  Future<bool> followSuggestion(String redId) async {
    final result = await _networkService.unirseRed(redId);
    if (!result.success) return false;
    _suggestionVisible = _suggestionVisible.where((e) => e.id != redId).toList();
    _suggestionIdsShownThisSession.add(redId);
    await _loadMyNetworks();
    if (_suggestionVisible.isEmpty) {
      _pickNewSuggestionBatch();
    }
    notifyListeners();
    return true;
  }

  /// Heurística de “no leído” sin API de leídos en el backend.
  bool showUnreadStyle(String conversationId, UltimoMensajeModel? ultimo) {
    if (_socketUnreadConversationIds.contains(conversationId)) return true;
    final uid = _sessionUserId;
    if (uid == null || ultimo == null) return false;
    final aid = ultimo.autorId;
    if (aid == null || aid.isEmpty) return false;
    return aid != uid;
  }

  void markConversationPreviewSeen(String conversationId) {
    if (_socketUnreadConversationIds.remove(conversationId)) {
      notifyListeners();
    }
  }

  Future<void> _pickNewSuggestionBatch() async {
    final mine = _myNetworks.map((e) => e.id).toSet();
    final allRes = await _networkService.getRedes();
    if (!allRes.success || allRes.data == null) {
      _suggestionVisible = [];
      return;
    }
    final pool = <SuggestedNetworkModel>[];
    for (final item in allRes.data!) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final model = SuggestedNetworkModel.fromApiMap(m);
      if (model.id.isEmpty) continue;
      if (mine.contains(model.id)) continue;
      if (_suggestionIdsShownThisSession.contains(model.id)) continue;
      pool.add(model);
    }
    pool.shuffle(_random);
    final take = pool.length < 10 ? pool.length : 10;
    _suggestionVisible = pool.take(take).toList();
    for (final s in _suggestionVisible) {
      _suggestionIdsShownThisSession.add(s.id);
    }
  }

  void _clearSession() {
    _sessionUserId = null;
    _removeSocketListeners();
    _conversations = [];
    _myNetworks = [];
    _suggestionVisible = [];
    _suggestionIdsShownThisSession.clear();
    _socketUnreadConversationIds.clear();
    _listStatus = InboxListStatus.success;
    _listError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.connectionPhase.removeListener(_onSocketPhase);
    _removeSocketListeners();
    super.dispose();
  }
}

/// Tiempo relativo compacto (estilo listas tipo Instagram).
String formatConversationTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  var diff = now.difference(t);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}sem';
}
