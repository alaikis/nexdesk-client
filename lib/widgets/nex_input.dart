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
    final wise = WiseTheme.of(context);

    final Color borderColor;
    final Color focusedBorderColor;

    if (widget.errorText != null) {
      borderColor = wise.error;
      focusedBorderColor = borderColor;
    } else if (_isFocused) {
      borderColor = wise.primary;
      focusedBorderColor = borderColor;
    } else {
      borderColor = wise.border;
      focusedBorderColor = borderColor;
    }

    final backgroundColor = wise.card;
    final disabledBackgroundColor = wise.backgroundSubtle;
    final textColor = wise.textPrimary;
    final hintColor = wise.textTertiary;
    final labelColor = wise.textSecondary;
    final radius = wise.radius.medium;

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
              color: widget.errorText != null ? wise.error : labelColor,
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
            fillColor: widget.enabled ? backgroundColor : disabledBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: wise.border),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: wise.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: wise.error, width: 1.5),
            ),
            errorText: null,
            errorStyle: TextStyle(
              fontSize: 12,
              color: wise.error,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: wise.error,
            ),
          ),
        ],
      ],
    );
  }
}
