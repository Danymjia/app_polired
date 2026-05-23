import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import 'safe_network_image.dart';

class NetworksListDialog extends StatelessWidget {
  final String username;
  final List<dynamic> networks;

  const NetworksListDialog({
    super.key,
    required this.username,
    required this.networks,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Redes de @$username',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppTheme.onSurface,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Fixed height to allow scrolling
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: networks.length,
          itemBuilder: (context, index) {
            final net = networks[index];
            final netId = net['_id'] ?? '';
            final netNombre = net['nombre'] ?? '';
            final netFoto = net['fotoPerfil'];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
                ),
                child: ClipOval(
                  child: netFoto != null && netFoto.toString().isNotEmpty
                      ? SafeNetworkImage(
                          url: netFoto.toString(),
                          fit: BoxFit.cover,
                          errorWidget: _buildPlaceholder(netNombre),
                        )
                      : _buildPlaceholder(netNombre),
                ),
              ),
              title: Text(
                netNombre,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.onSurface,
                ),
              ),
              onTap: () {
                if (netId.isNotEmpty) {
                  Navigator.pop(context);
                  context.push('/explore/networks/$netId');
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Regresar',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: AppTheme.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
