import 'package:flutter/material.dart';
import '../../core/screen_service.dart';
import '../../theme/app_theme.dart';

class ScreenSelector extends StatefulWidget {
  final List<ScreenInfo> screens;
  final Set<int> selectedIds;
  final Function(Set<int>) onSelectionChanged;

  const ScreenSelector({
    super.key,
    required this.screens,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<ScreenSelector> createState() => _ScreenSelectorState();
}

class _ScreenSelectorState extends State<ScreenSelector> {
  Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIds;
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected = _selected.where((i) => i != id).toSet();
      } else {
        _selected = {..._selected, id};
      }
    });
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final textTertiary = isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: NexSpacing.md,
        mainAxisSpacing: NexSpacing.md,
      ),
      itemCount: widget.screens.length,
      itemBuilder: (context, index) {
        final screen = widget.screens[index];
        final isSelected = _selected.contains(screen.id);
        return GestureDetector(
          onTap: () => _toggle(screen.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withValues(alpha: 0.1) : cardColor,
              borderRadius: BorderRadius.circular(NexRadius.md),
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.desktop_windows_outlined,
                    size: 32,
                    color: isSelected ? primaryColor : textTertiary,
                  ),
                ),
                if (screen.isPrimary)
                  Positioned(
                    top: NexSpacing.sm,
                    left: NexSpacing.sm,
                    child: Text(
                      'PRIMARY',
                      style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                Positioned(
                  bottom: NexSpacing.sm,
                  left: NexSpacing.sm,
                  right: NexSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        screen.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${screen.width}×${screen.height}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: NexSpacing.sm,
                    right: NexSpacing.sm,
                    child: Icon(Icons.check_circle, color: primaryColor, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
