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
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surface.withAlpha(230),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabs.length, (index) {
            final isActive = index == selectedIndex;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.only(bottom: 4),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppTheme.onSurface : AppTheme.outline,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ExploreTabsDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.tabs != tabs;
  }
}
