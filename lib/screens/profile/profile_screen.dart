import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../post/add_post_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/safe_network_image.dart';

/// Pantalla de Perfil de Usuario — diseño estilo Instagram/Threads minimalista.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkProvider>().fetchRedesDelEstudiante();
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String nombre, String apellido) {
    String out = '';
    if (nombre.isNotEmpty) out += nombre[0].toUpperCase();
    if (apellido.isNotEmpty) out += apellido[0].toUpperCase();
    return out;
  }

  Widget _buildAvatar(String? url, String initials) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(43),
        child: url != null && url.isNotEmpty
            ? SafeNetworkImage(
                url: url,
                fit: BoxFit.cover,
                errorWidget: _buildInitialsWidget(initials),
              )
            : _buildInitialsWidget(initials),
      ),
    );
  }

  Widget _buildInitialsWidget(String initials) {
    return Container(
      color: AppTheme.primaryText,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.primaryText,
          ),
        ),
      ],
    );
  }

  // ── Grid placeholder card ─────────────────────────────────────────────────

  Widget _buildGridCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.outlineVariant,
          size: 28,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final redesCount = context.watch<NetworkProvider>().redesCount;
    final bioDescripcion = user?.biografia?.trim();
    final initials = _initials(user?.nombre ?? '', user?.apellido ?? '');
    final isAdmin = user?.esAdminRed ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // "+" minimal icon — no container box
        leading: IconButton(
          icon: const Icon(Icons.add, color: AppTheme.primaryText, size: 26),
          tooltip: 'Nueva publicación',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPostScreen()),
            );
          },
        ),
        // Username with lock icon
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: AppTheme.primaryText),
            const SizedBox(width: 4),
            Text(
              user?.username ?? 'Perfil',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.primaryText, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: avatar | name + stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(user?.fotoPerfil, initials),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name (above stats)
                            Text(
                              user?.nombreCompleto ?? 'Cargando...',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildStat(
                                  user?.publicacionesCount.toString() ?? '0',
                                  'Publicaciones',
                                ),
                                const SizedBox(width: 28),
                                _buildStat(
                                  redesCount?.toString() ?? '0',
                                  'Redes',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bio (below avatar+name row)
                  if (bioDescripcion != null && bioDescripcion.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      bioDescripcion,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Action buttons ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainerLow,
                              foregroundColor: AppTheme.primaryText,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Editar perfil',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () {
                                // Placeholder for future admin web redirect
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gestión de red: próximamente'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Gestionar red',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Single tab: Publicaciones ──────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 0.8),
                  bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 0.8),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grid_on, size: 22, color: AppTheme.primaryText),
                  const SizedBox(width: 6),
                  Text(
                    'Publicaciones',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // ── 4-column grid ──────────────────────────────────────────────
            _buildGrid(user?.publicacionesCount ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(int count) {
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 56,
              color: AppTheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              'Aún no hay publicaciones',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Show placeholder tiles for each post (no navigation, no interaction)
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (_, i) => _buildGridCard(),
    );
  }
}
