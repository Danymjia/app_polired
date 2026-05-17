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

/// Pantalla de Perfil de Usuario.
/// Muestra estadísticas, biografía y una cuadrícula de publicaciones.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Carga el conteo de redes al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkProvider>().fetchRedesDelEstudiante();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final redesCount = context.watch<NetworkProvider>().redesCount;
    final bioDescripcion = user?.biografia?.trim();

    String initials = '';
    if (user != null) {
      if (user.nombre.isNotEmpty) initials += user.nombre[0].toUpperCase();
      if (user.apellido.isNotEmpty) initials += user.apellido[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.add_box_outlined,
            color: AppTheme.primaryText,
            size: 28,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPostScreen()),
            );
          },
        ),
        title: Text(
          user?.username ?? 'Perfil',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_horiz,
              color: AppTheme.primaryText,
              size: 28,
            ),
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
            // Profile Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 77,
                        height: 77,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(38.5),
                          child:
                              user?.fotoPerfil != null &&
                                  user!.fotoPerfil!.isNotEmpty
                              ? SafeNetworkImage(
                                  url: user.fotoPerfil,
                                  fit: BoxFit.cover,
                                  errorWidget: _buildInitialsAvatar(initials),
                                )
                              : _buildInitialsAvatar(initials),
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('0', 'Publicaciones'),
                            _buildStatColumn(
                              redesCount != null ? redesCount.toString() : '0',
                              'Redes',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bio
                  Text(
                    user?.nombreCompleto ?? 'Cargando...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  if (bioDescripcion != null && bioDescripcion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bioDescripcion,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
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
                      ),
                      child: const Text('Editar perfil'),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.grid_on,
                        size: 26,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Icon(
                        Icons.video_library_outlined,
                        size: 26,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            // Empty State for Grid
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_on_outlined,
                    size: 64,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay publicaciones',
                    style: GoogleFonts.inter(
                      fontSize: 14,
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

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryText),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
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
}
