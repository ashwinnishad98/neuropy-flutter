import 'package:flutter/material.dart';
import '../models/emotion.dart';

class EmotionCenterImage extends StatelessWidget {
  final int selectedEmotionIndex;
  final List<Emotion> emotions;

  const EmotionCenterImage(this.selectedEmotionIndex, this.emotions);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: selectedEmotionIndex == -1 ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: selectedEmotionIndex == -1
          ? null
          : Image.asset(
              emotions[selectedEmotionIndex].imagePath,
              fit: BoxFit.contain,
              key: ValueKey(selectedEmotionIndex),
              width: 140,
              height: 140,
            ),
    );
  }
}
