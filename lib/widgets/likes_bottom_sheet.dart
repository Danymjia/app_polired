import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/post_service.dart';
import 'safe_network_image.dart';

class LikesBottomSheet extends StatefulWidget {
  final String postId;

  const LikesBottomSheet({super.key, required this.postId});

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  bool _isLoading = true;
  List<dynamic> _likes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    try {
      final postService = context.read<PostService>();
      final result = await postService.getPostLikes(widget.postId);
      if (result.success && result.data != null) {
        setState(() {
          _likes = result.data!;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message ?? 'Error al cargar likes';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión';
      });
    }
  }

  String _getInitials(String nombre, String apellido) {
    final first = nombre.trim().isNotEmpty ? nombre.trim()[0] : '';
    final last = apellido.trim().isNotEmpty ? apellido.trim()[0] : '';
    final initials = '$first$last'.trim();
    return initials.isNotEmpty ? initials.toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          // Modal Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 0),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.surfaceContainer,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Me gusta',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadLikes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_likes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 48, color: AppTheme.outline),
            const SizedBox(height: 12),
            Text(
              'Aún no hay likes',
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: _likes.length,
      itemBuilder: (context, index) {
        final user = _likes[index];
        if (user is! Map) return const SizedBox.shrink();

        final nombre = user['nombre'] ?? '';
        final apellido = user['apellido'] ?? '';
        final username = user['username'] ?? '';
        final fotoPerfil = user['fotoPerfil'];

        final fullName = '$nombre $apellido'.trim();
        final displayUsername = username.isNotEmpty ? username : fullName.replaceAll(' ', '_').toLowerCase();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  CircularNetworkAvatar(
                    imageUrl: fotoPerfil,
                    initials: _getInitials(nombre, apellido),
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayUsername,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: -0.5,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          fullName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
