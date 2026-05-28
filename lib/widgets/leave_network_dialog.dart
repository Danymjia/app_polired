import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/network_provider.dart';
import '../providers/auth_provider.dart';

class LeaveNetworkDialog extends StatefulWidget {
  final String networkId;
  final String networkName;

  const LeaveNetworkDialog({
    super.key,
    required this.networkId,
    required this.networkName,
  });

  @override
  State<LeaveNetworkDialog> createState() => _LeaveNetworkDialogState();
}

class _LeaveNetworkDialogState extends State<LeaveNetworkDialog> {
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '¿Abandonar red?',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppTheme.onSurface,
        ),
      ),
      content: Text(
        '¿Estás seguro de que deseas salir de ${widget.networkName}? Ya no verás su feed de publicaciones exclusivas.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLeaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: _isLeaving ? null : () async {
            setState(() => _isLeaving = true);
            final netProvider = context.read<NetworkProvider>();
            final authProvider = context.read<AuthProvider>();
            final success = await netProvider.abandonarRed(widget.networkId);
            
            if (!context.mounted) return;
            setState(() => _isLeaving = false);
            Navigator.pop(context); // Cierra el dialog
            
            if (success) {
              // Sincronizar todo el perfil para reflejar cambios en contadores y lista de redes
              await authProvider.syncProfileFromServer();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.primary,
                  content: Text('Has abandonado la red ${widget.networkName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.error,
                  content: Text(netProvider.errorMessage ?? 'Error al abandonar la red'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: _isLeaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.error,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Abandonar',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
        ),
      ],
    );
  }
}
