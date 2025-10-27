// Custom Chrome-style tab indicator
import 'package:flutter/material.dart';

class ItineraryTabIndicator extends Decoration {
  final Color backgroundColor;
  final Color topBorderColor;
  final Color sideBorderColor;

  const ItineraryTabIndicator({
    required this.backgroundColor,
    required this.topBorderColor,
    required this.sideBorderColor,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _TabPainter(
      backgroundColor: backgroundColor,
      topBorderColor: topBorderColor,
      sideBorderColor: sideBorderColor,
    );
  }
}

class _TabPainter extends BoxPainter {
  final Color backgroundColor;
  final Color topBorderColor;
  final Color sideBorderColor;

  _TabPainter({
    required this.backgroundColor,
    required this.topBorderColor,
    required this.sideBorderColor,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );

    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Draw top border (thicker for better visibility)
    final topBorderPaint = Paint()
      ..color = topBorderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final topPath = Path()
      ..moveTo(rect.left + 12, rect.top)
      ..lineTo(rect.right - 12, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + 12),
        radius: const Radius.circular(12),
      );
    canvas.drawPath(topPath, topBorderPaint);

    // Draw side borders (slightly thicker)
    final sideBorderPaint = Paint()
      ..color = sideBorderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left border
    final leftPath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + 12)
      ..arcToPoint(
        Offset(rect.left + 12, rect.top),
        radius: const Radius.circular(12),
      );
    canvas.drawPath(leftPath, sideBorderPaint);

    // Right border
    final rightPath = Path()
      ..moveTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top + 12)
      ..arcToPoint(
        Offset(rect.right - 12, rect.top),
        radius: const Radius.circular(12),
        clockwise: false,
      );
    canvas.drawPath(rightPath, sideBorderPaint);
  }
}
