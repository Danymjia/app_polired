import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(209),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.surfaceContainerHigh.withAlpha(166),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            bottom: AppTheme.spacingS,
          ),
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                _ExploreIconButton(icon: Icons.add, onTap: () {}),
                const Spacer(),
                Text(
                  'Explorar',
                  style: AppTheme.displayMedium.copyWith(fontSize: 18, letterSpacing: -0.5),
                ),
                const Spacer(),
                _ExploreIconButton(icon: Icons.search_rounded, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ExploreIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppTheme.onSurface, size: 24),
      ),
    );
  }
}
