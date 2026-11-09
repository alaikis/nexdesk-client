import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    final wise = WiseTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: wise.card,
        border: Border(top: BorderSide(color: wise.border)),
      ),
      child: SafeArea(
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          indicatorColor: wise.primarySoft,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: items.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon, color: wise.textSecondary, size: 22),
              selectedIcon: Icon(item.icon, color: wise.primary, size: 22),
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
