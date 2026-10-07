import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/models/category_enum.dart';

class CategoryDonutData {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  const CategoryDonutData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class CategoryDonutPainter extends CustomPainter {
  final List<CategoryDonutData> data;
  final double animationProgress;
  final int? selectedIndex;
  final double strokeWidth;

  CategoryDonutPainter({
    required this.data,
    required this.animationProgress,
    this.selectedIndex,
    this.strokeWidth = 36.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - strokeWidth / 2 - 8;

    if (baseRadius <= 0) return;

    // Draw background track when empty
    if (data.isEmpty || data.every((d) => d.amount <= 0)) {
      final trackPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, baseRadius, trackPaint);
      return;
    }

    final double totalSweep = 2 * math.pi * animationProgress;
    double currentStartAngle = -math.pi / 2; // Start from top 12 o'clock

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item.percentage <= 0) continue;

      final sweepAngle = (item.percentage / 100.0) * totalSweep;
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = item.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 8 : strokeWidth
        ..strokeCap = StrokeCap.round;

      // When selected, pop out slightly along the bisector angle
      Offset segmentCenter = center;
      if (isSelected) {
        final bisectorAngle = currentStartAngle + sweepAngle / 2;
        const popDistance = 6.0;
        segmentCenter = Offset(
          center.dx + popDistance * math.cos(bisectorAngle),
          center.dy + popDistance * math.sin(bisectorAngle),
        );
      }

      final rect = Rect.fromCircle(
        center: segmentCenter,
        radius: isSelected ? baseRadius + 3 : baseRadius,
      );

      // Add slight gap between segments if multiple items exist
      final effectiveSweep = sweepAngle > 0.08 && data.length > 1
          ? sweepAngle - 0.05
          : sweepAngle;

      canvas.drawArc(
        rect,
        currentStartAngle,
        effectiveSweep,
        false,
        paint,
      );

      currentStartAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}
