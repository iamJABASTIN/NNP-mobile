import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A neo-brutalist button with thick border and offset shadow.
class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color shadowColor;
  final bool isLoading;
  final bool isCompact;

  const BrutalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primaryYellow,
    this.textColor = AppColors.black,
    this.shadowColor = AppColors.black,
    this.isLoading = false,
    this.isCompact = false,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel:
          isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 4 : 0,
          _isPressed ? 4 : 0,
          0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 12 : 24,
          vertical: widget.isCompact ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: isDisabled
              ? widget.backgroundColor.withAlpha(128)
              : widget.backgroundColor,
          border: Border.all(
            color: AppColors.black,
            width: BrutalDecorations.borderWidth,
          ),
          boxShadow: _isPressed || isDisabled
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: widget.textColor,
                ),
              )
            else if (widget.icon != null)
              Icon(widget.icon, size: 18, color: widget.textColor),
            if (widget.icon != null || widget.isLoading)
              const SizedBox(width: 8),
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: widget.isCompact ? 10 : 12,
                letterSpacing: 2.0,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
