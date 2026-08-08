import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';

class GaugeWidget extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String title;
  final String unit;
  final Color accentColor;
  final double size;

  const GaugeWidget({
    super.key,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 120.0,
    required this.title,
    required this.unit,
    this.accentColor = AutomotiveColors.cyanAccent,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final double normalizedValue = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              progress: normalizedValue,
              accentColor: accentColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: size * 0.07,
                  fontWeight: FontWeight.w600,
                  color: AutomotiveColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toInt().toString(),
                style: GoogleFonts.orbitron(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                  color: AutomotiveColors.textPrimary,
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: size * 0.07,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _GaugePainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Background track arc
    final bgPaint = Paint()
      ..color = AutomotiveColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Glowing progress arc
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [accentColor.withValues(alpha: 0.4), accentColor],
        transform: const GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = AutomotiveColors.textMuted
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 10; i++) {
      double angle = startAngle + (sweepAngle * (i / 10));
      double innerRadius = radius - 16;
      double outerRadius = radius - 8;

      Offset p1 = Offset(center.dx + innerRadius * cos(angle), center.dy + innerRadius * sin(angle));
      Offset p2 = Offset(center.dx + outerRadius * cos(angle), center.dy + outerRadius * sin(angle));

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
