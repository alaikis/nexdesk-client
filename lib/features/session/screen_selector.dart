import 'package:flutter/material.dart';
import '../../core/screen_service.dart';

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.screens.length,
      itemBuilder: (context, index) {
        final screen = widget.screens[index];
        final isSelected = _selected.contains(screen.id);
        return GestureDetector(
          onTap: () => _toggle(screen.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF007AFF).withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.desktop_windows_outlined,
                    size: 32,
                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                  ),
                ),
                if (screen.isPrimary)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Text(
                      'PRIMARY',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    '${screen.name}\n${screen.width}×${screen.height}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1D1D1F)),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle, color: Color(0xFF007AFF), size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
