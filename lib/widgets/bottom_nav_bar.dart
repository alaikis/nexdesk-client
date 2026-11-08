import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? const Color(0xFFE34234) : const Color(0xFFE34234);
    final unselectedColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          indicatorColor: selectedColor.withValues(alpha: 0.15),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: items.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon, color: unselectedColor, size: 24),
              selectedIcon: Icon(item.icon, color: selectedColor, size: 24),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}
