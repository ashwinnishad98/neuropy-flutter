import 'package:flutter/material.dart';
import 'dart:math';
import '../models/emotion.dart';

class EmotionWheelPainter extends CustomPainter {
  final List<Emotion> emotions;
  final int selectedEmotionIndex;

  EmotionWheelPainter(this.emotions, this.selectedEmotionIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final double anglePerSegment = (2 * pi) / emotions.length;

    const double gapWidth = 2.5;

    for (int i = 0; i < emotions.length; i++) {
      paint.color =
          i == selectedEmotionIndex ? emotions[i].color : const Color.fromARGB(255, 210, 210, 210); // sector color

      // Define start and end angles for each segment
      final double startAngle = i * anglePerSegment;
      final double endAngle = startAngle + anglePerSegment;

      // Define path for each segment with a radial gap
      final Path path = Path();

      // Move to the inner edge of the segment (with gap)
      path.moveTo(
        center.dx + gapWidth * cos(startAngle),
        center.dy + gapWidth * sin(startAngle),
      );

      // Draw the outer arc (excluding gaps)
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius - gapWidth),
        startAngle,
        anglePerSegment - (gapWidth / radius), // Exclude both sides of the gap
        false,
      );

      // Close path back to the inner edge of the next segment
      path.lineTo(
        center.dx + gapWidth * cos(endAngle),
        center.dy + gapWidth * sin(endAngle),
      );

      canvas.drawPath(path, paint);

      // Draw text label upright
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: emotions[i].label,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display')),
      );

      textPainter.layout();
      final double labelAngle = i * anglePerSegment + anglePerSegment / 2;
      final double textRadius = radius * .7;

      final double dx =
          center.dx + textRadius * cos(labelAngle) - textPainter.width / 2;
      final double dy =
          center.dy + textRadius * sin(labelAngle) - textPainter.height / 2;

      canvas.save();
      canvas.translate(dx + textPainter.width / 2, dy + textPainter.height / 2);
      canvas.translate(
          -(dx + textPainter.width / 2), -(dy + textPainter.height / 2));
      textPainter.paint(canvas, Offset(dx, dy));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
