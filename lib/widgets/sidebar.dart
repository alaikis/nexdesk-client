import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
    final wise = WiseTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: wise.card,
        border: Border(right: BorderSide(color: wise.border)),
      ),
      child: Column(
        children: [
          SizedBox(height: wise.spacing.md),
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
                selectedColor: wise.primary,
                iconColor: wise.textSecondary,
                hoverBgColor: wise.surface,
                selectedBgColor: wise.primarySoft,
                onTap: () => widget.onTap(index),
              ),
            );
          }),
          const Spacer(),
          if (widget.onLogout != null) ...[
            IconButton(
              onPressed: widget.onLogout,
              icon: Icon(Icons.logout, size: 20, color: wise.textSecondary),
              tooltip: l10n.logout,
            ),
            SizedBox(height: wise.spacing.xs),
          ],
          Container(
            width: 36,
            height: 36,
            margin: EdgeInsets.only(bottom: wise.spacing.md),
            decoration: BoxDecoration(
              color: wise.surface,
              borderRadius: BorderRadius.circular(wise.radius.sm),
              border: Border.all(color: wise.border),
            ),
            child: Icon(Icons.person_outline, size: 18, color: wise.textSecondary),
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
          duration: WiseMotionTokens.normal,
          curve: WiseMotionTokens.defaultCurve,
          width: 72,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected ? selectedBgColor : (isHovered ? hoverBgColor : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: selected ? selectedColor : iconColor),
        ),
      ),
    );
  }
}
