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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final cardColor = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;
    final borderColor = wise.border;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: wise.spacing.md,
        mainAxisSpacing: wise.spacing.md,
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
              borderRadius: BorderRadius.circular(wise.radius.medium),
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
                    top: wise.spacing.sm,
                    left: wise.spacing.sm,
                    child: Text(
                      'PRIMARY',
                      style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                Positioned(
                  bottom: wise.spacing.sm,
                  left: wise.spacing.sm,
                  right: wise.spacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        screen.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${screen.width}脳${screen.height}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: wise.spacing.sm,
                    right: wise.spacing.sm,
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
