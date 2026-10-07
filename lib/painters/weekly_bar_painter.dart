import 'dart:math' as math;
import 'package:flutter/material.dart';

class DaySpending {
  final int weekday; // 1 = Mon, ..., 7 = Sun
  final String label; // "Mon", "Tue", ...
  final double amount;

  const DaySpending({
    required this.weekday,
    required this.label,
    required this.amount,
  });
}

class WeeklyBarPainter extends CustomPainter {
  final List<DaySpending> days;
  final double animationProgress;
  final int? selectedIndex;
  final Color barColor;
  final Color selectedColor;

  WeeklyBarPainter({
    required this.days,
    required this.animationProgress,
    this.selectedIndex,
    this.barColor = const Color(0xFF818CF8), // Indigo 400
    this.selectedColor = const Color(0xFF4F46E5), // Indigo 600
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    final double maxAmount = days.map((d) => d.amount).fold(0.0, math.max);
    final double ceiling = maxAmount > 0 ? maxAmount * 1.2 : 100000.0;

    const double bottomLabelHeight = 24.0;
    final double chartHeight = size.height - bottomLabelHeight;
    final double barWidth = math.min(28.0, (size.width / (days.length * 1.8)));
    final double totalSlots = days.length.toDouble();
    final double slotWidth = size.width / totalSlots;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    const int gridSteps = 3;
    for (int step = 1; step <= gridSteps; step++) {
      final y = chartHeight - (chartHeight * (step / gridSteps));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Baseline
    final baseLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), baseLinePaint);

    // Draw each day bar
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final isSelected = selectedIndex == i;
      final centerX = slotWidth * i + (slotWidth / 2);

      // Height fraction
      final double normalizedHeight = (day.amount / ceiling).clamp(0.0, 1.0);
      final double currentHeight = (chartHeight * normalizedHeight * animationProgress);

      final left = centerX - (barWidth / 2);
      final top = chartHeight - currentHeight;
      final right = centerX + (barWidth / 2);
      final bottom = chartHeight;

      // Draw background pillar track
      final trackPaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, 0, right, chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Draw active spending bar
      if (currentHeight > 0) {
        final barPaint = Paint()
          ..color = isSelected ? selectedColor : barColor
          ..style = PaintingStyle.fill;

        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(left, top, right, bottom),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(barRect, barPaint);
      }

      // Draw label below bar
      final textPainter = TextPainter(
        text: TextSpan(
          text: day.label,
          style: TextStyle(
            color: isSelected ? selectedColor : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.days != days;
  }
}
