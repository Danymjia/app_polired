import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/public_profile_model.dart';
import 'safe_network_image.dart';

class PublicProfileHeader extends StatelessWidget {
  final PublicProfileModel profile;

  const PublicProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final initials = profile.nombre.isNotEmpty ? profile.nombre[0].toUpperCase() : '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircularNetworkAvatar(
                imageUrl: profile.fotoPerfil,
                initials: initials,
                size: 72,
                backgroundColor: AppTheme.surfaceContainerHighest,
                initialsStyle: GoogleFonts.inter(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nombreCompleto,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: null,
                tooltip: 'Chat deshabilitado',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.biografia != null && profile.biografia!.trim().isNotEmpty) ...[
            Text(
              profile.biografia!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _buildStatItem('Publicaciones', profile.publicacionesCount),
              const SizedBox(width: 24),
              _buildStatItem('Redes', profile.redesCount),
            ],
          ),
          const SizedBox(height: 20),
          if (profile.redes.isNotEmpty) ...[
            Text(
              'Redes comunitarias',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profile.redes.length,
                itemBuilder: (context, index) {
                  final net = profile.redes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      onPressed: () => context.push('/explore/networks/${net.id}'),
                      label: Text(
                        net.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceContainerLow,
                      side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
