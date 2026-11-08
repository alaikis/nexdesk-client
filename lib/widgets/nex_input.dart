import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NexInput extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const NexInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.prefixWidget,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<NexInput> createState() => _NexInputState();
}

class _NexInputState extends State<NexInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color borderColor;
    final Color focusedBorderColor;
    
    if (widget.errorText != null) {
      borderColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C);
      focusedBorderColor = borderColor;
    } else if (_isFocused) {
      borderColor = isDark ? const Color(0xFFE34234) : const Color(0xFFE34234);
      focusedBorderColor = borderColor;
    } else {
      borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE);
      focusedBorderColor = borderColor;
    }

    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final hintColor = isDark ? const Color(0xFF78716C) : const Color(0xFF9C958D);
    final labelColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.errorText != null 
                  ? (isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C))
                  : labelColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          focusNode: _focusNode,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              color: hintColor,
            ),
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, size: 18, color: hintColor)
                : null,
            prefix: widget.prefixWidget,
            filled: true,
            fillColor: widget.enabled ? backgroundColor : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexRadius.md),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
                width: 1.5,
              ),
            ),
            errorText: null,
            errorStyle: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ],
    );
  }
}
