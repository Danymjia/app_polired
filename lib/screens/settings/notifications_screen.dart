import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _emailEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preferencias de notificaciones',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notificaciones push'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    title: 'Me gusta',
                    subtitle: 'Notificar cuando alguien reacciona a tu contenido',
                    icon: Icons.favorite_border_outlined,
                    value: _likesEnabled,
                    onChanged: (val) => setState(() => _likesEnabled = val),
                    showDivider: true,
                  ),
                  _buildSwitchItem(
                    title: 'Comentarios',
                    subtitle: 'Notificar cuando alguien escribe en tus publicaciones',
                    icon: Icons.chat_bubble_outline_outlined,
                    value: _commentsEnabled,
                    onChanged: (val) => setState(() => _commentsEnabled = val),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('Correo electrónico'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: _buildSwitchItem(
                title: 'Anuncios de la universidad',
                subtitle: 'Novedades, eventos importantes y avisos de facultad',
                icon: Icons.mail_outline_outlined,
                value: _emailEnabled,
                onChanged: (val) => setState(() => _emailEnabled = val),
                showDivider: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.outline,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppTheme.outlineVariant.withValues(alpha: 0.5),
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  return Colors.transparent;
                }),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: AppTheme.surfaceContainerHigh,
            height: 1,
            indent: 72,
          ),
      ],
    );
  }
}
