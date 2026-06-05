import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/conversation_model.dart';
import '../../models/network_story_model.dart';
import '../../models/suggested_network_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_inbox_provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/socket_service.dart';
import '../../services/navigation_bus.dart';
import '../../models/events/post_event.dart';
import '../../models/feed_context.dart';

/// Responsabilidad principal:
/// Pantalla Bandeja de Entrada (Inbox) para listar conversaciones activas, estado de la conexión en vivo y sugerencias de nuevas redes a seguir.
///
/// Flujo dentro de la app:
/// Muestra dinámicamente un banner de estado del `SocketService`. Consume la lista de chats del `MessagesInboxProvider` y permite Forzar-Recarga mediante un `RefreshIndicator`.
///
/// Dependencias críticas:
/// - `MessagesInboxProvider` (Manejo de estado de la bandeja).
/// - `AuthProvider` (Extracción del userId actual para determinar el remitente/destinatario).
///
/// Side Effects:
/// - Peticiones múltiples en inicialización: Renderiza carruseles secundarios (Sugerencias y Stories) que disparan peticiones extra.
///
/// Recordatorios técnicos y CQRS:
/// - Violación de Responsabilidad Única (SRP): Esta pantalla mezcla "Mis Conversaciones" con "Redes Sugeridas" y "Mis Redes (Historias)". El `MessagesInboxProvider` realiza peticiones a endpoints de *Redes* en lugar de enfocarse solo en *Chat*, creando duplicación de estado masiva con el `NetworkProvider` y el `ExploreNetworksProvider`.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final auth = context.watch<AuthProvider>();
    final inbox = context.watch<MessagesInboxProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => inbox.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top + 8)),
            SliverToBoxAdapter(
              child: _MessagesHeader(username: user?.username),
            ),
            SliverToBoxAdapter(child: _SearchFieldPlaceholder()),
            SliverToBoxAdapter(child: _SocketBanner(phase: inbox.socketPhase)),
            SliverToBoxAdapter(
              child: _NetworkStoriesRow(user: user, networks: inbox.myNetworks),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Mensajes',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ),
            ..._conversationSlivers(inbox, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Redes para seguir',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SuggestionsSection(
                items: inbox.suggestionVisible,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _conversationSlivers(
    MessagesInboxProvider inbox,
    UserModel? user,
  ) {
    switch (inbox.listStatus) {
      case InboxListStatus.loading:
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ConversationRowSkeleton(delayIndex: i),
                  ),
                ),
              ),
            ),
          ),
        ];
      case InboxListStatus.error:
        return [
          SliverToBoxAdapter(
            child: _InboxErrorState(
              message: inbox.listError ?? 'Error al cargar',
              onRetry: () => inbox.refresh(),
            ),
          ),
        ];
      case InboxListStatus.empty:
        return [const SliverToBoxAdapter(child: _EmptyConversationsState())];
      case InboxListStatus.success:
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final c = inbox.conversations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _ConversationTile(
                  conversation: c,
                  currentUserId: user?.id ?? '',
                  unreadStyle: inbox.showUnreadStyle(c.id, c.ultimoMensaje),
                ),
              );
            }, childCount: inbox.conversations.length),
          ),
        ];
    }
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    final label = username != null && username!.trim().isNotEmpty
        ? '@$username'
        : 'Mensajes';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _SearchFieldPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Buscar',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF71717A),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFFA1A1AA),
          ),
          filled: true,
          fillColor: const Color(0xFFF4F4F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SocketBanner extends StatelessWidget {
  const _SocketBanner({required this.phase});

  final SocketConnectionPhase phase;

  @override
  Widget build(BuildContext context) {
    late final String message;
    var bg = const Color(0xFFFFF7ED);
    var fg = const Color(0xFF9A3412);
    switch (phase) {
      case SocketConnectionPhase.connected:
        return const SizedBox.shrink();
      case SocketConnectionPhase.connecting:
        message = 'Conectando en tiempo real…';
        break;
      case SocketConnectionPhase.reconnecting:
        message = 'Reconectando…';
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
      case SocketConnectionPhase.disconnected:
        message =
            'Sin conexión en tiempo real. Los mensajes pueden llegar con retraso.';
        bg = const Color(0xFFF4F4F5);
        fg = const Color(0xFF52525B);
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(message),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkStoriesRow extends StatelessWidget {
  const _NetworkStoriesRow({required this.user, required this.networks});

  final UserModel? user;
  final List<NetworkStoryModel> networks;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          if (currentUser != null) 
            InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => context.read<NavigationBus>().dispatch(FocusPostEvent(postId: '', context: FeedContext.profile(userId: currentUser.id))),
              child: _UserStoryChip(user: currentUser),
            ),
          if (networks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 20),
              child: Text(
                'Aún no te has unido a ninguna red.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF71717A)),
              ),
            ),
          ...networks.map(
            (n) => Padding(
              padding: const EdgeInsets.only(left: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => context.push('/explore/networks/${n.id}'),
                child: _NetworkStoryChip(network: n),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserStoryChip extends StatelessWidget {
  const _UserStoryChip({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final handle = user.username != null && user.username!.trim().isNotEmpty
        ? '@${user.username}'
        : user.nombreCompleto.split(' ').first;
    final url = user.fotoPerfil;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: url != null && url.isNotEmpty
                ? SafeNetworkImage(
                    url: url,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: _initialsAvatar(user.nombre),
                  )
                : _initialsAvatar(user.nombre),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _NetworkStoryChip extends StatelessWidget {
  const _NetworkStoryChip({required this.network});

  final NetworkStoryModel network;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: network.imageUrl.isNotEmpty
                ? SafeNetworkImage(
                    url: network.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: _acronymFill(network.acronym),
                  )
                : _acronymFill(network.acronym),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            network.acronym,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _initialsAvatar(String name) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  return Container(
    color: const Color(0xFFF4F4F5),
    alignment: Alignment.center,
    child: Text(
      letter,
      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22),
    ),
  );
}

Widget _acronymFill(String acronym) {
  return Container(
    color: const Color(0xFFF4F4F5),
    alignment: Alignment.center,
    child: Text(
      acronym,
      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11),
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.unreadStyle,
  });

  final ConversationModel conversation;
  final String currentUserId;
  final bool unreadStyle;

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final name = peer?.displayName ?? 'Usuario';
    final url = peer?.fotoPerfil;
    final lastMsg = conversation.ultimoMensaje;
    String preview = 'Sin mensajes aún';
    if (lastMsg != null && (lastMsg.contenido?.trim().isNotEmpty ?? false)) {
      final isFromMe = lastMsg.autorId == currentUserId;
      final prefix = isFromMe ? 'Tú: ' : '';
      preview = '$prefix${lastMsg.contenido}';
    }
    final time = formatConversationTime(conversation.ultimaActividad);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<MessagesInboxProvider>().markConversationPreviewSeen(
            conversation.id,
          );
          context.push(
            '/chat/${conversation.id}',
            extra: {
              'contactId': peer?.id,
              'contactName': peer?.displayName,
              'contactAvatar': peer?.fotoPerfil,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircularNetworkAvatar(
                imageUrl: url,
                initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
                size: 56,
                backgroundColor: const Color(0xFFF4F4F5),
                initialsStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (unreadStyle)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: unreadStyle
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: unreadStyle
                                  ? AppTheme.primaryText
                                  : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationRowSkeleton extends StatefulWidget {
  const _ConversationRowSkeleton({required this.delayIndex});

  final int delayIndex;

  @override
  State<_ConversationRowSkeleton> createState() =>
      _ConversationRowSkeletonState();
}

class _ConversationRowSkeletonState extends State<_ConversationRowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(min: 0.35, max: 1.0, reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = CurvedAnimation(parent: _c, curve: Curves.easeInOut).value;
        final base = Color.lerp(
          const Color(0xFFEEEEEE),
          const Color(0xFFF5F5F5),
          v,
        )!;
        return Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyConversationsState extends StatelessWidget {
  const _EmptyConversationsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes conversaciones',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando hables con alguien, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF71717A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxErrorState extends StatelessWidget {
  const _InboxErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({
    required this.items,
  });

  final List<SuggestedNetworkModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Text(
          'No hay más redes sugeridas por ahora.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF71717A),
          ),
        ),
      );
    }
    return Column(
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _SuggestionRow(
            model: e,
          ),
        );
      }).toList(),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.model,
  });

  final SuggestedNetworkModel model;

  @override
  Widget build(BuildContext context) {
    final desc = model.descripcion.trim();
    final short = desc.length > 80 ? '${desc.substring(0, 80)}…' : desc;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/explore/networks/${model.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF4F4F5),
              child: Text(
                model.acronym,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (short.isNotEmpty)
                    Text(
                      short,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
