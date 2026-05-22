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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5), width: 1),
                ),
                padding: const EdgeInsets.all(2),
                child: CircularNetworkAvatar(
                  imageUrl: profile.fotoPerfil,
                  initials: initials,
                  size: 77,
                  backgroundColor: AppTheme.surfaceContainerHighest,
                  initialsStyle: GoogleFonts.inter(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Publicaciones', profile.publicacionesCount),
                    _buildStatItem('Redes', profile.redesCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.nombreCompleto,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (profile.biografia != null && profile.biografia!.trim().isNotEmpty) ...[
            Text(
              profile.biografia!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (profile.redes.isNotEmpty) ...[
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
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceContainerLow,
                      side: const BorderSide(color: Colors.transparent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
