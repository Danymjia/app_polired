import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/public_user_model.dart';
import '../repositories/conversations_repository.dart';
import 'safe_network_image.dart';

/// Responsabilidad principal:
/// Renderiza un item de lista para un usuario en resultados de búsqueda, con acceso directo a su perfil o para iniciar un chat.
///
/// Flujo dentro de la app:
/// Usado en listas de búsqueda y sugerencias (ej. `NetworkSearchDelegate`).
///
/// Dependencias críticas:
/// - `ConversationsRepository` (Para obtener o crear la conversación de chat).
/// - `go_router` (Navegación al perfil o chat).
///
/// Side Effects:
/// - Petición de red silenciosa al presionar el botón de chat (`getOrCreateConversation`).
///
/// Recordatorios técnicos y CQRS:
/// - Usa estado local (`_isLoading`) para prevenir múltiples clicks mientras se crea la conversación en el backend.
class UserSearchTile extends StatefulWidget {
  final PublicUserModel user;

  const UserSearchTile({super.key, required this.user});

  @override
  State<UserSearchTile> createState() => _UserSearchTileState();
}

class _UserSearchTileState extends State<UserSearchTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final initials = user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/explore/public-profile/${user.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircularNetworkAvatar(
              imageUrl: user.fotoPerfil,
              initials: initials,
              size: 44,
              backgroundColor: AppTheme.surfaceContainerHighest,
              initialsStyle: GoogleFonts.inter(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombreCompleto,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    onPressed: () async {
                      if (_isLoading) return;
                      setState(() => _isLoading = true);

                      final repo = context.read<ConversationsRepository>();
                      final result = await repo.getOrCreateConversation(user.id);

                      if (!mounted || !context.mounted) return;
                      setState(() => _isLoading = false);

                      if (result.success && result.data != null) {
                        context.push(
                          '/chat/${result.data}',
                          extra: {
                            'contactId': user.id,
                            'contactName': user.nombreCompleto,
                            'contactAvatar': user.fotoPerfil,
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message ?? 'Error al iniciar conversación')),
                        );
                      }
                    },
                    tooltip: 'Mensaje',
                  ),
          ],
        ),
      ),
    );
  }
}
