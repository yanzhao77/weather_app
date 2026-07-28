import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class HudPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final bool showCornerBracket;

  const HudPanel({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.showCornerBracket = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(AppConstants.panelBorderRadius),
        border: Border.all(color: AppColors.borderGlow, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          if (showCornerBracket) ...[
            // Top-left bracket
            const Positioned(
              top: -1,
              left: -1,
              child: _CornerBracket(isTopLeft: true),
            ),
            // Top-right bracket
            const Positioned(
              top: -1,
              right: -1,
              child: _CornerBracket(isTopLeft: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTopLeft;
  const _CornerBracket({required this.isTopLeft});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _CornerBracketPainter(isTopLeft: isTopLeft),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final bool isTopLeft;
  _CornerBracketPainter({required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (isTopLeft) {
      canvas.drawLine(const Offset(0, 18), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(18, 0), paint);
    } else {
      canvas.drawLine(
          Offset(size.width - 18, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
