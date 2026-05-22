import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/public_user_model.dart';
import 'safe_network_image.dart';

class UserSearchTile extends StatelessWidget {
  final PublicUserModel user;

  const UserSearchTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
              onPressed: () {},
              tooltip: 'Mensaje',
            ),
          ],
        ),
      ),
    );
  }
}
