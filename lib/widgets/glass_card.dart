import 'package:flutter/material.dart';
import '../theme/automotive_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor ?? AutomotiveColors.cardBorder,
        width: 1.2,
      ),
    );

    final cardContent = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: backgroundColor ?? AutomotiveColors.cardBackground.withValues(alpha: 0.85),
        shape: shapeBorder,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: backgroundColor ?? AutomotiveColors.cardBackground.withValues(alpha: 0.85),
          shape: shapeBorder,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }

    return cardContent;
  }
}
