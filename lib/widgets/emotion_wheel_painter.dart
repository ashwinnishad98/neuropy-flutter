import 'package:flutter/material.dart';
import 'dart:math';
import '../models/emotion.dart';

class EmotionWheelPainter extends CustomPainter {
  EmotionWheelPainter(this.emotions, this.selectedEmotionIndex);

  final List<Emotion> emotions;
  final int selectedEmotionIndex;

  final double _shrinkFactor = 0.93;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseOuterRadius = size.width / 2; // Standard outer radius
    final double baseInnerRadius =
        baseOuterRadius * 0.4; // Standard inner radius

    const double segmentGap = 6.0; // Gap between segments
    const double strokeWidth = 0.0; // Width for segment borders

    final double anglePerSegment = (2 * pi) / emotions.length;

    for (int i = 0; i < emotions.length; i++) {
      if (i == selectedEmotionIndex) continue;

      // Use original color
      Color segmentColor = emotions[i].color;

      // For unselected segments, use smaller radius without animation
      double outerRadius = baseOuterRadius * _shrinkFactor;
      double innerRadius = baseInnerRadius;

      // Calculate angles for this segment
      final double startAngle = i * anglePerSegment - pi / 2;
      final double endAngle =
          startAngle + anglePerSegment - (segmentGap / outerRadius);

      final Path segmentPath = Path()
        ..moveTo(center.dx + innerRadius * cos(startAngle),
            center.dy + innerRadius * sin(startAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius),
            startAngle, anglePerSegment - (segmentGap / outerRadius), false)
        ..lineTo(center.dx + outerRadius * cos(endAngle),
            center.dy + outerRadius * sin(endAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), endAngle,
            -(anglePerSegment - (segmentGap / outerRadius)), false)
        ..close();

      // Fill the segment
      final Paint fillPaint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(segmentPath, fillPaint);

      final Paint strokePaint = Paint()
        ..color = segmentColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      canvas.drawPath(segmentPath, strokePaint);

      // Draw the labels
      drawSegmentLabel(
          canvas, center, i, anglePerSegment, innerRadius, outerRadius);
    }

    if (selectedEmotionIndex >= 0) {
      int i = selectedEmotionIndex;
      Color segmentColor = emotions[i].color;

      double outerRadius = baseOuterRadius;
      double innerRadius = baseInnerRadius;

      // Calculate angles for this segment
      final double startAngle = i * anglePerSegment - pi / 2;
      final double endAngle =
          startAngle + anglePerSegment - (segmentGap / outerRadius);

      final Path segmentPath = Path()
        ..moveTo(center.dx + innerRadius * cos(startAngle),
            center.dy + innerRadius * sin(startAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius),
            startAngle, anglePerSegment - (segmentGap / outerRadius), false)
        ..lineTo(center.dx + outerRadius * cos(endAngle),
            center.dy + outerRadius * sin(endAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), endAngle,
            -(anglePerSegment - (segmentGap / outerRadius)), false)
        ..close();

      // Fill the segment
      final Paint fillPaint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(segmentPath, fillPaint);

      final Paint strokePaint = Paint()
        ..color = segmentColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      canvas.drawPath(segmentPath, strokePaint);

      // Draw the labels
      drawSegmentLabel(
          canvas, center, i, anglePerSegment, innerRadius, outerRadius);
    }

    // Draw center circle to create clean inner edge
    final Paint centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseInnerRadius - strokeWidth / 2, centerPaint);

    final Paint innerBorderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
        center, baseInnerRadius - strokeWidth / 2, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is EmotionWheelPainter) {
      return oldDelegate.selectedEmotionIndex != selectedEmotionIndex;
    }
    return true;
  }

  // Helper method to draw the segment labels
  void drawSegmentLabel(Canvas canvas, Offset center, int index,
      double anglePerSegment, double innerRadius, double outerRadius) {
    // Determine if this is the selected emotion
    bool isSelected = index == selectedEmotionIndex;

    // Calculate the actual midRadius based on whether this is selected or not
    final double midRadius = isSelected
        ? (innerRadius + outerRadius) / 2 * 1.03 // Slightly larger for selected
        : (innerRadius + outerRadius) /
            2 *
            0.97; // Slightly smaller for unselected

    final midAngle = index * anglePerSegment +
        anglePerSegment / 2 -
        pi / 2; // Start from top

    // Get the current emotion label
    final String label = emotions[index].label;

    // Default position values
    double adjustedRadius = midRadius;
    double horizontalOffset = 0;

    // Apply special adjustments for specific emotions
    if (label == 'Curiosity') {
      horizontalOffset = -11.0; // Negative value moves it left
    }

    double fontSize = isSelected ? 20.0 : 19.0;
    FontWeight fontWeight = isSelected ? FontWeight.bold : FontWeight.w600;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.1,
        ),
      ),
    );

    textPainter.layout();

    // Calculate base position
    double x =
        center.dx + adjustedRadius * cos(midAngle) - textPainter.width / 2;
    double y =
        center.dy + adjustedRadius * sin(midAngle) - textPainter.height / 2;

    // Apply horizontal offset for specific labels
    x += horizontalOffset;

    canvas.save();
    canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
    canvas.translate(
        -(x + textPainter.width / 2), -(y + textPainter.height / 2));
    textPainter.paint(canvas, Offset(x, y));
    canvas.restore();
  }
}
