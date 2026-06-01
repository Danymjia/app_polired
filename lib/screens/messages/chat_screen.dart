import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/socket_service.dart';
import '../../widgets/safe_network_image.dart';
import '../../providers/messages_inbox_provider.dart';

/// Responsabilidad principal:
/// Pantalla de conversación 1:1. Renderiza el historial de mensajes e integra una caja de texto para el envío bidireccional vía WebSockets.
///
/// Flujo dentro de la app:
/// Se instancia con un `conversationId`. Crea localmente un `ChatProvider` y lo provee a sus widgets hijos. Escucha el ScrollController inversamente para disparar paginación histórica (`loadMore`).
///
/// Dependencias críticas:
/// - `ChatProvider` (Paginación histórica REST + Eventos en tiempo real Pusher).
/// - `MessagesInboxProvider` (Para actualizar la previsualización del último mensaje globalmente).
///
/// Side Effects:
/// - Provider efímero: El `ChatProvider` nace y muere con la pantalla, no es un singleton.
///
/// Recordatorios técnicos y CQRS:
/// - Fuga de Abstracción: El uso del callback `onMessageSent` para actualizar manualmente el `MessagesInboxProvider` es un anti-patrón. El Inbox debería escuchar directamente los eventos del `SocketService` para auto-actualizarse sin depender de que la vista del chat esté activa e invocando callbacks.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String contactId;
  final String contactName;
  final String? contactAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.contactId,
    required this.contactName,
    this.contactAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider(
      socketService: SocketService(),
      conversationId: widget.conversationId,
      contactId: widget.contactId,
      currentUserId: context.read<AuthProvider>().user?.id ?? '',
      onMessageSent: (msg, author, date) {
        if (mounted) {
          context.read<MessagesInboxProvider>().updateConversationPreview(
            widget.conversationId, msg, author, date);
        }
      },
    );
  }

  @override
  void dispose() {

    _chatProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: _ChatScreenContent(
        conversationId: widget.conversationId,
        contactName: widget.contactName,
        contactAvatar: widget.contactAvatar,
        currentUserId: context.read<AuthProvider>().user?.id ?? '',
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String? contactAvatar;
  final String currentUserId;

  const _ChatScreenContent({
    required this.conversationId,
    required this.contactName,
    this.contactAvatar,
    required this.currentUserId,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF4F4F5),
              ),
              clipBehavior: Clip.hardEdge,
              child: widget.contactAvatar != null && widget.contactAvatar!.isNotEmpty
                  ? SafeNetworkImage(
                      url: widget.contactAvatar!,
                      fit: BoxFit.cover,
                      errorWidget: _initialsAvatar(widget.contactName),
                    )
                  : _initialsAvatar(widget.contactName),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE4E4E7), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: provider.isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: messages.length + (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              ),
                            ),
                          );
                        }

                        final msg = messages[i];
                        final isMe = msg.autorId == widget.currentUserId;
                        
                        // ¿Es el último del grupo? (el que lleva la cola)
                        // Como estamos en reverse, i=0 es el último.
                        final isLastInGroup = i == 0 || messages[i - 1].autorId != msg.autorId;
                        
                        // Separador de fecha (con i+1 porque i+1 es el mensaje más viejo)
                        bool showDateSeparator = false;
                        if (i == messages.length - 1) {
                          showDateSeparator = true;
                        } else {
                          final prevMsg = messages[i + 1];
                          if (prevMsg.createdAt.day != msg.createdAt.day || 
                              prevMsg.createdAt.month != msg.createdAt.month || 
                              prevMsg.createdAt.year != msg.createdAt.year) {
                            showDateSeparator = true;
                          }
                        }

                        return Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (showDateSeparator) _buildDateSeparator(msg.createdAt),
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: isLastInGroup ? 4 : 2,
                                      left: isMe ? 48 : 0,
                                      right: isMe ? 0 : 48,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF1E3A8A) : const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(!isMe && isLastInGroup ? 4 : 20),
                                        bottomRight: Radius.circular(isMe && isLastInGroup ? 4 : 20),
                                      ),
                                    ),
                                    child: Text(
                                      msg.contenido,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isLastInGroup)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12, top: 2),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(msg.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFA1A1AA),
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check,
                                        size: 14,
                                        color: msg.leido ? const Color(0xFF3B82F6) : const Color(0xFFA1A1AA),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            _buildInput(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String text;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      text = 'Hoy';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      text = 'Ayer';
    } else {
      text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInput(BuildContext context, ChatProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) {
                  setState(() {
                    _isTyping = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Mensaje...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFA1A1AA),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: _isTyping ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _isTyping
                  ? () {
                      provider.sendMessage(_textController.text);
                      _textController.clear();
                      setState(() {
                        _isTyping = false;
                      });
                    }
                  : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTyping ? const Color(0xFF0F172A) : const Color(0xFFE4E4E7),
                ),
                child: Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping ? Colors.white : const Color(0xFFA1A1AA),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }
}
