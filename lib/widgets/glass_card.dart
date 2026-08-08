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
  final bool showCornerReticles;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 14.0,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.showCornerReticles = false,
  });

  @override
  Widget build(BuildContext context) {
    final shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor ?? AutomotiveColors.stroke,
        width: 1.0,
      ),
    );

    final tileBg = backgroundColor ?? AutomotiveColors.glassPanel;

    Widget cardBody = Material(
      color: tileBg,
      shape: shapeBorder,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (!showCornerReticles) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: cardBody,
      );
    }

    // Wrap with subtle brand corner reticles for sensing/auto-detect elements
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Stack(
        children: [
          cardBody,
          Positioned(
            top: 4,
            left: 4,
            child: _buildReticleCorner(isTop: true, isLeft: true),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _buildReticleCorner(isTop: true, isLeft: false),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: _buildReticleCorner(isTop: false, isLeft: true),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: _buildReticleCorner(isTop: false, isLeft: false),
          ),
        ],
      ),
    );
  }

  Widget _buildReticleCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AutomotiveColors.electricCyan, width: 1.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AutomotiveColors.electricCyan, width: 1.5) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AutomotiveColors.electricCyan, width: 1.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AutomotiveColors.electricCyan, width: 1.5) : BorderSide.none,
        ),
      ),
    );
  }
}
