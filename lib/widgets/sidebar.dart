import 'package:flutter/material.dart';

class NexSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<SidebarItem> items;

  const NexSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      color: cs.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = index == selectedIndex;
            return _SidebarTile(
              icon: item.icon,
              label: item.label,
              selected: selected,
              onTap: () => onTap(index),
            );
          }),
          const Spacer(),
          // User avatar placeholder
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person, size: 18, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  const SidebarItem({required this.icon, required this.label});
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
