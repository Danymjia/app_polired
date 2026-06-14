import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Responsabilidad principal:
/// Muestra el historial de "Strikes" (advertencias o infracciones) asociadas a la cuenta del usuario actual, y alerta si está suspendido.
///
/// Flujo dentro de la app:
/// Accesible desde `SettingsScreen` -> "Mis advertencias".
///
/// Dependencias críticas:
/// - `AuthProvider` (lee directamente del usuario cacheado).
///
/// Side Effects:
/// - Despacha `syncProfileFromServer()` en el Pull-to-Refresh para forzar la actualización del estado de strikes.
///
/// Recordatorios técnicos y CQRS:
/// - Refleja la lógica de negocio de baneos del backend (5 strikes = cuenta suspendida).
class StrikesScreen extends StatelessWidget {
  const StrikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final suspendido = user?.suspendido ?? false;
    final strikes = user?.strikes ?? [];

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mis advertencias',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.onBackground,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => context.read<AuthProvider>().syncProfileFromServer(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildStatusCard(suspendido, strikes.length),
            const SizedBox(height: 24),
            Text(
              'HISTORIAL DE ADVERTENCIAS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            if (strikes.isEmpty)
              _buildEmptyState()
            else
              ...strikes.reversed.map((strike) => _buildStrikeCard(strike)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool suspendido, int count) {
    if (!suspendido && count == 0) {
      return const SizedBox.shrink();
    }

    if (suspendido) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta suspendida',
                    style: GoogleFonts.inter(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Has acumulado 5 advertencias formales.',
                    style: GoogleFonts.inter(
                      color: Colors.red.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppTheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tienes $count de 5 advertencias',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Al acumular 5 tu cuenta será suspendida.',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 64, color: AppTheme.onBackground),
            const SizedBox(height: 16),
            Text(
              'Sin advertencias activas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrikeCard(dynamic strike) {
    final tipoRaw = strike['tipoReporte'] as String? ?? 'Reporte';
    final tipoStr = '${tipoRaw[0].toUpperCase()}${tipoRaw.substring(1).toLowerCase()}';
    
    final motivo = strike['motivo'] as String? ?? 'Infracción de normas comunitarias';
    
    String fechaStr = '';
    if (strike['fecha'] != null) {
      try {
        final date = DateTime.parse(strike['fecha']).toLocal();
        fechaStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade700.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reporte de $tipoStr',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      Text(
                        fechaStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    motivo,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
