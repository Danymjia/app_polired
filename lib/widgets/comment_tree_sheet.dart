import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/post_service.dart';
import '../providers/post_store_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'safe_network_image.dart';

/// Responsabilidad principal:
/// Renderizar y gestionar el árbol de comentarios de un Post dentro de un BottomSheet interactivo. Soporta hilos de respuestas aplanados visualmente.
///
/// Flujo dentro de la app:
/// Llama a `PostService` para obtener el árbol anidado. Aplica un algoritmo DFS (Depth First Search) para aplanar la lista conservando el hilo lógico (Flattening). Tras enviar un comentario, despacha la orden hacia el `PostStoreProvider` para propagar el conteo al UI subyacente.
///
/// Dependencias críticas:
/// - `PostService` (HTTP requests para lecturas y escrituras directas).
/// - `PostStoreProvider` (Sincronización optimista del contador global).
///
/// Side Effects:
/// - Acoplamiento JSON: El parseo `(userId['nombre'] ?? '')` se hace inline en lugar de usar factorías en modelos formales.
///
/// Recordatorios técnicos y CQRS:
/// - Riesgo de Escalabilidad (OOM): `getCommentsTree` descarga todo el árbol de comentarios en una sola petición. En un escenario de alta viralidad (miles de comentarios), colapsará la memoria de la aplicación. Urge implementar paginación cursiva o carga diferida por nodo padre.

// ────────────────────────────────────────────────────────
// Lightweight data models for in-memory use only
// ────────────────────────────────────────────────────────

class _CommentAuthor {
  final String displayName;
  final String username;
  final String? imageUrl;
  _CommentAuthor({required this.displayName, required this.username, this.imageUrl});
}

class _FlatReply {
  final String id;
  final _CommentAuthor author;
  final String content;
  final String timeAgo;
  /// Non-null when this reply answers another reply (not the root comment).
  final String? replyingToUsername;

  const _FlatReply({
    required this.id,
    required this.author,
    required this.content,
    required this.timeAgo,
    this.replyingToUsername,
  });
}

class _RootComment {
  final String id;
  final _CommentAuthor author;
  final String content;
  final String timeAgo;
  final List<_FlatReply> replies;
  bool repliesExpanded;

  _RootComment({
    required this.id,
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.replies,
    required this.repliesExpanded,
  });
}

// ────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────

_CommentAuthor _parseAuthor(dynamic userId) {
  if (userId is! Map) {
    return _CommentAuthor(displayName: 'Usuario', username: 'usuario');
  }
  final nombre = (userId['nombre'] ?? '').toString().trim();
  final apellido = (userId['apellido'] ?? '').toString().trim();
  final username = (userId['username'] ?? '').toString().trim();
  final displayName = '$nombre $apellido'.trim();
  final fotoPerfil = userId['fotoPerfil']?.toString();
  return _CommentAuthor(
    displayName: displayName.isNotEmpty ? displayName : 'Usuario',
    username: username.isNotEmpty ? username : (displayName.isNotEmpty ? displayName : 'usuario'),
    imageUrl: fotoPerfil,
  );
}

String _timeAgo(String? createdAt) {
  if (createdAt == null) return '';
  try {
    final date = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  } catch (_) {
    return '';
  }
}

/// Flattens a recursive `hijos` tree into a single-level reply list.
/// The [rootAuthorUsername] is the username of the root comment's author.
/// When a reply's direct parent is NOT the root, we prepend @parentUsername.
List<_FlatReply> _flattenReplies(
  List<dynamic> hijos,
  String rootCommentId,
) {
  final List<_FlatReply> result = [];

  // We do a DFS with each node's immediate parent id recorded.
  void traverse(dynamic node, String? directParentId) {
    final author = _parseAuthor(node['userId']);
    final nodeId = node['_id']?.toString() ?? '';

    // This reply directly answers another reply (not the root comment)
    final bool isReplyToReply = directParentId != null && directParentId != rootCommentId;
    String? replyingToUsername;

    if (isReplyToReply) {
      // directParentId is the id of the reply being answered — we need its author.
      // We derive it from the existing result list.
      final parent = result.where((r) => r.id == directParentId).firstOrNull;
      replyingToUsername = parent?.author.username;
    }

    result.add(_FlatReply(
      id: nodeId,
      author: author,
      content: (node['contenido'] ?? '').toString(),
      timeAgo: _timeAgo(node['createdAt']?.toString()),
      replyingToUsername: replyingToUsername,
    ));

    final children = node['hijos'];
    if (children is List && children.isNotEmpty) {
      for (final child in children) {
        traverse(child, nodeId);
      }
    }
  }

  for (final hijo in hijos) {
    traverse(hijo, rootCommentId);
  }

  return result;
}

/// Converts raw backend tree into flat _RootComment list.
List<_RootComment> _parseComments(List<dynamic> raw) {
  return raw.map((c) {
    final id = c['_id']?.toString() ?? '';
    final author = _parseAuthor(c['userId']);
    final hijos = c['hijos'];
    final replies = hijos is List && hijos.isNotEmpty
        ? _flattenReplies(hijos, id)
        : <_FlatReply>[];
    return _RootComment(
      id: id,
      author: author,
      content: (c['contenido'] ?? '').toString(),
      timeAgo: _timeAgo(c['createdAt']?.toString()),
      replies: replies,
      repliesExpanded: false,
    );
  }).toList();
}

// ────────────────────────────────────────────────────────
// Widget
// ────────────────────────────────────────────────────────

class CommentTreeSheet extends StatefulWidget {
  final String postId;

  const CommentTreeSheet({super.key, required this.postId});

  @override
  State<CommentTreeSheet> createState() => _CommentTreeSheetState();
}

class _CommentTreeSheetState extends State<CommentTreeSheet> {
  bool _isLoading = true;
  bool _isSending = false;
  List<_RootComment> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  // Null = composing a root comment; non-null = replying to something.
  String? _replyToCommentId;  // the ID sent to the API (always the root comment id OR a reply id)
  String? _replyToUsername;   // shown in the "Respondiendo a @..." banner

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // ── Data loading ──────────────────────────────────────

  Future<void> _loadComments() async {
    List<dynamic> raw = [];
    try {
      final postService = context.read<PostService>();
      final result = await postService.getCommentsTree(widget.postId);

      if (result.success && result.data != null) {
        if (result.data is Map && (result.data as Map)['comentarios'] != null) {
          raw = (result.data as Map)['comentarios'] as List<dynamic>;
        } else if (result.data is List) {
          raw = result.data as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _comments = _parseComments(raw);
          _isLoading = false;
        });
      }
    }
  }

  // ── Submission ────────────────────────────────────────

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final postService = context.read<PostService>();
    final postStore = context.read<PostStoreProvider>();

    try {
      final result = _replyToCommentId != null
          ? await postService.replyComment(_replyToCommentId!, text)
          : await postService.createComment(widget.postId, text);

      if (result.success) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
          _replyToUsername = null;
        });
        postStore.incrementCommentsCount(widget.postId);
        await _loadComments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Error al enviar comentario')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Reply target helpers ──────────────────────────────

  void _setReplyTarget(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
  }

  void _clearReplyTarget() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Comentarios',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.surfaceContainerHigh),

            // List
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [CircularProgressIndicator(color: AppTheme.primary)],
                      ),
                    )
                  : _comments.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _comments.length,
                          itemBuilder: (ctx, i) => _buildRootComment(_comments[i]),
                        ),
            ),

            // Input
            _buildInput(),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(
            'Sé el primero en comentar',
            style: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Root comment ──────────────────────────────────────

  Widget _buildRootComment(_RootComment c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(radius: 18, imageUrl: c.author.imageUrl, name: c.author.displayName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _authorHeader(c.author.displayName, c.timeAgo, large: true),
                    const SizedBox(height: 4),
                    Text(
                      c.content,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    _replyButton(() => _setReplyTarget(c.id, c.author.username), large: true),
                  ],
                ),
              ),
            ],
          ),

          // Expand/collapse replies toggle
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: GestureDetector(
                onTap: () => setState(() => c.repliesExpanded = !c.repliesExpanded),
                child: Row(
                  children: [
                    Container(width: 24, height: 1, color: AppTheme.outlineVariant),
                    const SizedBox(width: 10),
                    Text(
                      c.repliesExpanded
                          ? 'Ocultar respuestas'
                          : 'Ver ${c.replies.length} ${c.replies.length == 1 ? 'respuesta' : 'respuestas'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Flat replies list — all at the same indent level
          if (c.repliesExpanded && c.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...c.replies.map((r) => _buildFlatReply(r, c.id)),
          ],
        ],
      ),
    );
  }

  // ── Flat reply (same level for all) ──────────────────

  Widget _buildFlatReply(_FlatReply reply, String rootCommentId) {
    return Padding(
      // Fixed left indent — never grows deeper
      padding: const EdgeInsets.only(left: 48, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(radius: 14, imageUrl: reply.author.imageUrl, name: reply.author.displayName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _authorHeader(reply.author.displayName, reply.timeAgo, large: false),
                const SizedBox(height: 3),
                // Content with optional @mention prefix
                _buildReplyContent(reply),
                const SizedBox(height: 5),
                // "Responder" tap targets the *root* comment so the reply
                // goes into the same flat list, but we show @username in the banner.
                _replyButton(
                  () => _setReplyTarget(reply.id, reply.author.username),
                  large: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyContent(_FlatReply reply) {
    if (reply.replyingToUsername == null) {
      return Text(
        reply.content,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.onSurface, height: 1.35),
      );
    }

    // Inline @mention prefix
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '@${reply.replyingToUsername} ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          TextSpan(
            text: reply.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.onSurface,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────

  Widget _avatar({required double radius, String? imageUrl, required String name}) {
    return CircularNetworkAvatar(
      imageUrl: imageUrl,
      initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
      size: radius * 2,
      backgroundColor: AppTheme.surfaceContainerHighest,
      initialsStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
      ),
    );
  }

  Widget _authorHeader(String name, String time, {required bool large}) {
    return Row(
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: large ? 13 : 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: GoogleFonts.inter(fontSize: large ? 11 : 10, color: AppTheme.outline),
        ),
      ],
    );
  }

  Widget _replyButton(VoidCallback onTap, {required bool large}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Responder',
        style: GoogleFonts.inter(
          fontSize: large ? 12 : 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.outline,
        ),
      ),
    );
  }

  // ── Input area ────────────────────────────────────────

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 36,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply banner
          if (_replyToUsername != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 12),
              child: Row(
                children: [
                  Text(
                    'Respondiendo a @$_replyToUsername',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearReplyTarget,
                    child: const Icon(Icons.close, size: 16, color: AppTheme.outline),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Consumer<AuthProvider>(
                builder: (context, auth, _) => CircularNetworkAvatar(
                  imageUrl: auth.user?.fotoPerfil,
                  initials: (auth.user?.nombre.isNotEmpty ?? false) ? auth.user!.nombre[0].toUpperCase() : '?',
                  size: 36,
                  backgroundColor: AppTheme.surfaceContainerHighest,
                  initialsStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                          decoration: InputDecoration(
                            hintText: _replyToUsername != null
                                ? 'Añade una respuesta...'
                                : 'Añade un comentario...',
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.outline),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      if (_isSending)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      else
                        GestureDetector(
                          onTap: _submitComment,
                          child: const Icon(Icons.send, color: AppTheme.primary, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
