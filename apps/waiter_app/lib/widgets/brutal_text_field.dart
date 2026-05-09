import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Neo-brutalist text field with thick black border and yellow focus ring.
class BrutalTextField extends StatefulWidget {
  final String? label;
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;
  final bool obscureText;
  final bool readOnly;
  final FocusNode? focusNode;

  const BrutalTextField({
    super.key,
    this.label,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.autofocus = false,
    this.obscureText = false,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  State<BrutalTextField> createState() => _BrutalTextFieldState();
}

class _BrutalTextFieldState extends State<BrutalTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
              color: _focusNode.hasFocus ? AppColors.primaryYellow : AppColors.black,
              width: BrutalDecorations.borderWidth,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
              color: AppColors.black,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText.toUpperCase(),
              hintStyle: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
                color: AppColors.black.withAlpha(26),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}
