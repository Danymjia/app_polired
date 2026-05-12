import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'home/home_screen.dart';
import 'post/add_post_screen.dart';
import 'profile/profile_screen.dart';

/// Pantalla contenedor principal que gestiona la navegación por pestañas (Bottom Navigation).
/// Utiliza un [IndexedStack] para mantener el estado de cada sección.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('Explorar - Próximamente'))),
    const AddPostScreen(),
    const Scaffold(body: Center(child: Text('Mensajes - Próximamente'))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Needed for transparent/blur bottom nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              border: const Border(
                top: BorderSide(
                  color: Colors.black12,
                  width: 1.0,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen()));
                  return;
                }
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: AppTheme.primaryText,
              unselectedItemColor: AppTheme.onSurfaceVariant,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 28),
                  activeIcon: Icon(Icons.home, size: 28),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search, size: 28),
                  label: 'Explorar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined, size: 28),
                  activeIcon: Icon(Icons.add_box, size: 28),
                  label: 'Publicar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline, size: 28),
                  activeIcon: Icon(Icons.chat_bubble, size: 28),
                  label: 'Mensajes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 28),
                  activeIcon: Icon(Icons.person, size: 28),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
