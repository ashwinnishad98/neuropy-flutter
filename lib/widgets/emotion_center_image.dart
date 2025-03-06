import 'package:flutter/material.dart';
import '../models/emotion.dart';

class EmotionCenterImage extends StatelessWidget {
  final int selectedEmotionIndex;
  final List<Emotion> emotions;
  final bool isVisible;

  const EmotionCenterImage(this.selectedEmotionIndex, this.emotions, 
      {Key? key, this.isVisible = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedEmotionIndex == -1) return const SizedBox();

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Image.asset(
        emotions[selectedEmotionIndex].imagePath,
        width: 120,
        height: 120,
      ),
    );
  }
}
