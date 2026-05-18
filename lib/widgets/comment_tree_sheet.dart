import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/post_service.dart';
import '../providers/post_store_provider.dart';
import 'package:provider/provider.dart';

class CommentTreeSheet extends StatefulWidget {
  final String postId;

  const CommentTreeSheet({super.key, required this.postId});

  @override
  State<CommentTreeSheet> createState() => _CommentTreeSheetState();
}

class _CommentTreeSheetState extends State<CommentTreeSheet> {
  bool _isLoading = true;
  bool _isSending = false;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  
  String? _replyToCommentId;
  String? _replyToUsername;

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

  Future<void> _loadComments() async {
    List<dynamic> loaded = [];
    try {
      final postService = context.read<PostService>();
      final result = await postService.getCommentsTree(widget.postId);

      if (result.success && result.data != null) {
        if (result.data is Map && (result.data as Map)['comentarios'] != null) {
          loaded = (result.data as Map)['comentarios'] as List<dynamic>;
        } else if (result.data is List) {
          loaded = result.data as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _comments = loaded; // datos + redraw en un solo setState
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Cachear providers antes del await para evitar uso de BuildContext across async gaps
    final postService = context.read<PostService>();
    final postStore = context.read<PostStoreProvider>();

    try {
      final result = _replyToCommentId != null
          ? await postService.replyComment(_replyToCommentId!, text)
          : await postService.createComment(widget.postId, text);

      if (result.success) {
        _commentController.clear();
        _replyToCommentId = null;
        _replyToUsername = null;
        postStore.incrementCommentsCount(widget.postId);
        // Refresh the whole tree to get the new comment
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
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle & Header
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
          
          // Comments List
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentNode(comment);
                    },
                  ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 40),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          onTap: () {
                            setState(() {
                              _replyToCommentId = null;
                              _replyToUsername = null;
                            });
                          },
                          child: const Icon(Icons.close, size: 16, color: AppTheme.outline),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      child: Icon(Icons.person, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(24),
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
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.outline,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                            if (_isSending)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              )
                            else
                              GestureDetector(
                                onTap: _submitComment,
                                child: Icon(Icons.send, color: AppTheme.primary, size: 20),
                              ),
                          ],
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
    );
  }

  Widget _buildCommentNode(dynamic comment, {bool isReply = false}) {
    final hasChildren = comment['hijos'] != null && (comment['hijos'] as List).isNotEmpty;
    
    // Parse author info from populated userId
    final author = comment['userId'];
    String authorName = 'Usuario';
    if (author is Map) {
      final nombre = author['nombre'] ?? '';
      final apellido = author['apellido'] ?? '';
      authorName = '$nombre $apellido'.trim();
      if (authorName.isEmpty) authorName = 'Usuario';
    }

    // Time Ago
    String timeAgo = '';
    if (comment['createdAt'] != null) {
      try {
        final date = DateTime.parse(comment['createdAt']).toLocal();
        final diff = DateTime.now().difference(date);
        if (diff.inMinutes < 60) {
          timeAgo = 'Hace ${diff.inMinutes}m';
        } else if (diff.inHours < 24) {
          timeAgo = 'Hace ${diff.inHours}h';
        } else {
          timeAgo = 'Hace ${diff.inDays}d';
        }
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 16 : 20,
                backgroundColor: AppTheme.surfaceContainerHighest,
                child: Icon(Icons.person, size: isReply ? 20 : 24, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: GoogleFonts.inter(
                            fontSize: isReply ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: isReply ? 10 : 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['contenido'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyToCommentId = comment['_id'];
                          _replyToUsername = authorName;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            'Responder',
                            style: GoogleFonts.inter(
                              fontSize: isReply ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasChildren && !isReply) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: AppTheme.outlineVariant,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Ver ${(comment['hijos'] as List).length} respuestas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.favorite_border, size: 20, color: AppTheme.outline),
              ),
            ],
          ),
        ),
        if (hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Column(
              children: (comment['hijos'] as List).map((child) => _buildCommentNode(child, isReply: true)).toList(),
            ),
          ),
      ],
    );
  }
}
