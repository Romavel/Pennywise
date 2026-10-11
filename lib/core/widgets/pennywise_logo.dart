import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// App mark: a stack of coins on an orange rounded tile.
class PennywiseLogo extends StatelessWidget {
  const PennywiseLogo({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.accent,
        borderRadius: BorderRadius.circular(size * 0.3125),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.54),
        painter: const _CoinsPainter(AppPalette.onAccent),
      ),
    );
  }
}

/// Draws the 48×48 coin-stack icon from the design, scaled to [size].
class _CoinsPainter extends CustomPainter {
  const _CoinsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 14), width: 28, height: 11),
      paint,
    );
    for (final top in [14.0, 24.0]) {
      final bottom = top + 10;
      final path = Path()
        ..moveTo(10, top)
        ..lineTo(10, bottom)
        ..cubicTo(10, bottom + 3, 16.3, bottom + 5.5, 24, bottom + 5.5)
        ..cubicTo(31.7, bottom + 5.5, 38, bottom + 3, 38, bottom)
        ..lineTo(38, top);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter oldDelegate) => oldDelegate.color != color;
}
