import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class NexSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<SidebarItem> items;
  final VoidCallback? onLogout;

  const NexSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.onLogout,
  });

  @override
  State<NexSidebar> createState() => _NexSidebarState();
}

class _NexSidebarState extends State<NexSidebar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final selectedBgColor = isDark ? const Color(0xFF0A84FF).withValues(alpha: 0.15) : const Color(0xFF007AFF).withValues(alpha: 0.1);
    final selectedIconColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final iconColor = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final hoverBgColor = isDark ? const Color(0xFF38383A) : const Color(0xFFF2F2F7);

    return Container(
      width: 72,
      color: backgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = index == widget.selectedIndex;
            final isHovered = _hoveredIndex == index;
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: _SidebarTile(
                icon: item.icon,
                label: item.label,
                selected: selected,
                isHovered: isHovered,
                selectedColor: selectedIconColor,
                iconColor: iconColor,
                hoverBgColor: hoverBgColor,
                selectedBgColor: selectedBgColor,
                onTap: () => widget.onTap(index),
              ),
            );
          }),
          const Spacer(),
          if (widget.onLogout != null) ...[
            IconButton(
              onPressed: widget.onLogout,
              icon: Icon(Icons.logout, size: 20, color: iconColor),
              tooltip: l10n.logout,
            ),
            const SizedBox(height: 4),
          ],
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: selectedBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person, size: 18, color: selectedIconColor),
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
  final bool isHovered;
  final Color selectedColor;
  final Color iconColor;
  final Color hoverBgColor;
  final Color selectedBgColor;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isHovered,
    required this.selectedColor,
    required this.iconColor,
    required this.hoverBgColor,
    required this.selectedBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? selectedBgColor : (isHovered ? hoverBgColor : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: selected ? selectedColor : iconColor),
        ),
      ),
    );
  }
}
