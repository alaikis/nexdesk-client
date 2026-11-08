import 'package:flutter/material.dart';

class OnlineDot extends StatefulWidget {
  final bool isOnline;
  final double size;

  const OnlineDot({super.key, required this.isOnline, this.size = 8});

  @override
  State<OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<OnlineDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onlineColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37);
    final offlineColor = isDark ? const Color(0xFF78716C) : const Color(0xFF9C958D);
    final color = widget.isOnline ? onlineColor : offlineColor;

    if (!widget.isOnline) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = _animation.value;
        final progress = (scale - 1.0) / 0.3;
        final ringOpacity = (1.0 - progress).clamp(0.0, 1.0);
        return SizedBox(
          width: widget.size * 1.3,
          height: widget.size * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: ringOpacity * 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
