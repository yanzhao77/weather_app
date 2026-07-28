import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ScanlineOverlay extends StatelessWidget {
  final double opacity;
  final double lineHeight;
  final double spacing;

  const ScanlineOverlay({
    super.key,
    this.opacity = 0.03,
    this.lineHeight = 1.0,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScanlinePainter(
          color: AppColors.accentCyan.withValues(alpha: opacity),
          lineHeight: lineHeight,
          spacing: spacing,
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final Color color;
  final double lineHeight;
  final double spacing;

  _ScanlinePainter({
    required this.color,
    required this.lineHeight,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineHeight;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing + lineHeight;
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => false;
}
