import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A neo-brutalist card with thick black border and offset shadow.
class BrutalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool hasShadow;

  const BrutalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        border: Border.all(
          color: AppColors.black,
          width: BrutalDecorations.borderWidth,
        ),
        boxShadow: hasShadow
            ? const [
                BoxShadow(
                  color: AppColors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
