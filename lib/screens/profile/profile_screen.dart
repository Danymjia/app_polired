import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../post/add_post_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de Perfil de Usuario.
/// Muestra estadísticas, biografía y una cuadrícula de publicaciones.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
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
          icon: const Icon(Icons.add_box_outlined, color: AppTheme.primaryText, size: 28),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen()));
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
            icon: const Icon(Icons.more_horiz, color: AppTheme.primaryText, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(38.5),
                          child: user?.fotoPerfil != null && user!.fotoPerfil!.isNotEmpty
                              ? Image.network(
                                  user.fotoPerfil!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(initials),
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
                            _buildStatColumn('156', 'Publicaciones'),
                            _buildStatColumn('12', 'Redes'),
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
                  const SizedBox(height: 2),
                  Text(
                    'Ingeniería @ Stanford | 2025 | Entusiasta de la Robótica',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
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
                  top: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
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
                      child: const Icon(Icons.grid_on, size: 26, color: Colors.black),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Icon(Icons.video_library_outlined, size: 26, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80), // To avoid covering by BottomNavBar
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final urls = [
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCJezasDNnqZuIVZpyicUuRhBJEqbpWlBYk0glBQ9zIGG8Lo2JIpH7AStMdGsAHsMHJTHGQCPjITpcf5sNfdZVbrS-Oval6uFXTkJ0nw2bNGG90HwIU-h7V5u2lCgNuXVdTNz2Un8tIxlqObthVfcPi-kUwKZsUpcoi6W8luBelv7TJFsP6hHPfltsVKOEi12kwln7oBFEe4LGXWsnawhgjlfhSDBi-VInXI8ZO-ObCzDH-bNzMQPZ4kMjA-VNUPTBHwAaHO-wzk-tB',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDnM5ytNgXw3DMsCD5y7S79BvYnHDEp-C3t1txwEabiwcCMiZvr_9FWdwr35vkbRjoTTxHszGffUhgFYlX8j3jB_kMgA4I1AeWr6HUqux9uBQjfonq5BaXivE6KXjlgFdEUlxXsrHG_mWVHgAlrAerJFNyMCRHVdGlmDW8dmmslCNAXFcPHvXDy7WK7yWN5RJf9xtIDbLIsZPprPef2imgpe0Zcm_0Vp_rfpJiwLy4qPvv95TImtieAok-RSOC8k45z4HcpJyVnP_FI',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAHQqe6QyPRdgIyuGAv10QpsSwPtxU-CmYcFnh62ho3q_bWYOFiwQqFukmLTAFXiWYOXXAevMsk1VBIprM0qN8_HbuGioVSN6F15_5wKnAi3JQNFUwekO7BexTL3ZEkGTDJWBliMyJY0a6GuekrDidnB6T6htblvR5tyBhpQRHiiM5rmz3YPIML4ydEwHHOuZVYtf9e3sYdYbth_XyfbW2bdPw4I1-YBCLPVeKuDEmgvcztsgSTH3I9fB7NH-W5J1dMgiuhvK9WnFCq',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCi4xUIihPYzk0bowZ5B_Q3wnQsqrWxfkO_VQPda9TFElPppwISdJ81YTveVEe4uALfZmY80C8MdYJHX4a_IKp-jjkGF7_hE0TUc9zOoqQr2ZMyrLcBRcAW6pvYzyFQtdjgyvphSPW7bKqJM2n2TnwHVeNqtcFSPnEpgfpXwz5-9dIpgv65RZ082QAtEdHE1sde-iEDZfWJCcNsm1bEOoHIc5cGiDlQA0sNryACgL_eMDSiHeqPNHPi9a5Z481BFeMZ8GB6mUY5o8WQ',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCLiOZsp_57NKB0Hk11pAGQSwLDCm4OHCCQj3OLZcy1YMryX12PtvAiptHc0f0RvrZMzfscpttgDfHdgTX9Pfn6mYNx-K4Z_f8qJNey-XOaLSR97ylFRhBec641dIiKQRsH9h1MPKU1bduEj5ytcenkXs2SFtWkf-iOA7QVGp4Tb4QXU8i325VIBKK494uTCJmdhYfaR9h-DnYRclHP7OL-iLjzjgTFHMKcxcthIDVTL4I1DLqy6uyF3r8CqgArQdVeWaUzVbfGzjvE',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDrcnQc0-Wgck0lhcy0_s-oX1kJoWrxSV6rylA3PHgBnM-eJt178jrnga7IdZlB4qIrTl3QPmyWICHLd8TEW4ln4Gwpz9gEhBCIlpd0wfDCd-NidclavGlqmN4dCCuhVSpfEtjEhafGBQ0ZIBSnYr30tvc1_xjB82uc_KzIeip14JdFfjH1YFuw-h5BHTtcr1juIdAv2rOLfqulbPwpnpnQvtSNyi9m15p0N8p-P1sxF3wfLLuqFAdncDLFONbim9bnsfhuSXQLTjqQ',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDxnwRMm21905ys0QToF4VBSbBj95k0gEAOeMLYabdSUVTDeXduiQzCo-zb6YvoZER-xl7sTsd58gN9Uy7vwfHRrOLi1T_372HKBukT2duB6XMla4FTibJIXfY-lY1DfaQvHhncYjDHcOAlVdZYZMAZNppenyS39f-4tV_pNFcLFsmN2nrOmFu8NLYvFiVFkb0yB01-J--kYDRnN7pdk6v0816tJPaAKGECasDcjYZhLS33mWL_Khlw4-cY18JzAL2XRYHEAo9EQlVP',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDQiTjRhRY-hc0G7u-cejeJq2ysnXliIKfWaGfUwBL24V7I830s-F7U6-LPTRj9YT0F28hFd-jgkTV_xcMOjNN_iLvOHeUodcL_VURTH_RhjUd1qvJDlRzYiTLtgCYIX-soY5o0lAMTdLtftXaMCqYUVu7KlZFtxhp7J8WW5iJrGhvhD-j5mzRAvDrdZAlI86d8kZsoTiAz45-gF6r56XB7IZGYHEGWRG3ehROTAWaHc5PK4vADesI1Ym3IkekZwTLuwylWwEkN4D2_',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCT4ZQ92Cmp9uaPfwNlwxLL0FGtFozH6MYxFyITZAgAwyAizYEHgRlhd0pUNg9FByFNlvl6szwl-LZv_4AN71nzlfx5zdUGAv4xhSUzIH1lrNpxF2PyO4IZcgM0yYcsvO0qn_8zRoc9xJWu49BjS3ORp-rDavNmfv6TSquiwTB6A9ovrdJcTESiFtrylP0GId2B2iXMO86n-ImR70C5IneUGv7SdfHkN8KLzSvfrej9h26xqciBsuLcLrXGz5UJIQnjHqWMKrDFgQzv',
                ];
                return Container(
                  color: AppTheme.surfaceContainerLow,
                  child: Image.network(
                    urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image)),
                  ),
                );
              },
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
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.primaryText,
          ),
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
