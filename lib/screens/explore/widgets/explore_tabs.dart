import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ExploreTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  const ExploreTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ExploreTabsDelegate(
        selectedIndex: selectedIndex,
        tabs: tabs,
        onTabSelected: onTabSelected,
      ),
    );
  }
}

class _ExploreTabsDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  _ExploreTabsDelegate({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surface.withAlpha(235),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(tabs.length, (index) {
              final isActive = index == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.surfaceContainerLowest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs[index],
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isActive
                                ? AppTheme.onSurface
                                : AppTheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: 3,
                          width: isActive ? 28 : 0,
                          decoration: BoxDecoration(
                            color: AppTheme.onSurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ExploreTabsDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.tabs != tabs;
  }
}
