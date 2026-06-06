import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/public_profile_model.dart';
import 'safe_network_image.dart';
import 'fullscreen_image_viewer.dart';

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
              GestureDetector(
                onTap: () {
                  if (profile.fotoPerfil != null && profile.fotoPerfil!.isNotEmpty) {
                    FullscreenImageViewer.show(context, [profile.fotoPerfil!], isCircular: true);
                  }
                },
                child: Container(
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
            InkWell(
              onTap: () => _showNetworksModal(context, profile.redes),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Miembro de: ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: profile.redes[0].nombre,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (profile.redes.length > 1)
                        TextSpan(
                          text: ' y ${profile.redes.length - 1} más',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
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

  void _showNetworksModal(BuildContext context, List<PublicProfileNetworkModel> redesList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.5,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 0),
                child: Column(
                  children: [
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
                        'Redes a las que pertenece',
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
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: redesList.length,
                  itemBuilder: (context, index) {
                    final net = redesList[index];
                    final netId = net.id;
                    final netNombre = net.nombre;
                    final netFoto = net.fotoPerfil;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(modalContext);
                          if (netId.isNotEmpty) {
                            context.push('/explore/networks/$netId');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              CircularNetworkAvatar(
                                imageUrl: netFoto,
                                initials: netNombre.isNotEmpty ? netNombre[0].toUpperCase() : 'R',
                                size: 48,
                                backgroundColor: AppTheme.surfaceContainerLow,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      netNombre,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: -0.5,
                                        color: AppTheme.primary,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
