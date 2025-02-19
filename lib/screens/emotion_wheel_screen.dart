import 'package:flutter/material.dart';
import '../widgets/emotion_wheel_painter.dart';
import '../widgets/emotion_center_image.dart';
import '../services/firestore_service.dart';
import 'dart:math';
import '../models/emotion.dart';

class EmotionWheelScreen extends StatefulWidget {
  const EmotionWheelScreen({super.key});

  @override
  _EmotionWheelScreenState createState() => _EmotionWheelScreenState();
}

class _EmotionWheelScreenState extends State<EmotionWheelScreen> {
  final List<Emotion> emotions = [
    const Emotion(
      label: 'Joy',
      color: Color.fromARGB(255, 247, 197, 34),
      imagePath: 'assets/joy.png',
    ),
    const Emotion(
      label: 'Trust',
      color: Color.fromARGB(255, 171, 216, 101),
      imagePath: 'assets/trust.png',
    ),
    const Emotion(
      label: 'Fear',
      color: Color.fromARGB(255, 124, 227, 255),
      imagePath: 'assets/fear.png',
    ),
    const Emotion(
      label: 'Surprise',
      color: Color.fromARGB(255, 115, 233, 210),
      imagePath: 'assets/surprise.png',
    ),
    const Emotion(
      label: 'Sadness',
      color: Color.fromARGB(255, 62, 112, 252),
      imagePath: 'assets/sadness.png',
    ),
    const Emotion(
      label: 'Disgust',
      color: Color.fromARGB(255, 202, 130, 253),
      imagePath: 'assets/disgust.png',
    ),
    const Emotion(
      label: 'Anger',
      color: Color.fromARGB(255, 255, 126, 63),
      imagePath: 'assets/anger.png',
    ),
    const Emotion(
      label: 'Anticipation',
      color: Color.fromARGB(255, 255, 125, 156),
      imagePath: 'assets/anticipation.png',
    ),
  ];

  int selectedEmotionIndex = -1;
  double emotionIntensity = 1;
  bool isImageVisible = false; // Controls image visibility for animation

  void onTapDown(TapDownDetails details, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset touchPoint = details.localPosition;

    final double dx = touchPoint.dx - center.dx;
    final double dy = touchPoint.dy - center.dy;
    double angle = atan2(dy, dx);

    if (angle < 0) angle += 2 * pi;

    final double anglePerSegment = (2 * pi) / emotions.length;
    final int tappedSegment = (angle / anglePerSegment).floor();

    if (tappedSegment == selectedEmotionIndex) {
      // Deselect the segment if it was tapped again
      setState(() {
        selectedEmotionIndex = -1;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          isImageVisible = true;
        });
      });
    } else {
      // If a new emotion is clicked, update index and trigger animation
      setState(() {
        selectedEmotionIndex = tappedSegment;
        isImageVisible = false;
      });
    }
  }

  Future<void> submitEmotion() async {
    if (selectedEmotionIndex == -1) {
      // No emotion selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select an emotion before proceeding.")),
      );
      return;
    }

    try {
      await FirestoreService.addEmotion(
        emotions[selectedEmotionIndex].label,
        emotionIntensity.toInt(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emotion submitted successfully!")),
      );
      setState(() {
        selectedEmotionIndex = -1;
        emotionIntensity = 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting emotion: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Mood'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            const Text(
              "How are you feeling now?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTapDown: (details) =>
                      onTapDown(details, const Size(320, 320)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter:
                            EmotionWheelPainter(emotions, selectedEmotionIndex),
                        child: const SizedBox(width: 400, height: 400),
                      ),
                      EmotionCenterImage(selectedEmotionIndex, emotions),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // Slider for Emotion Intensity
                Slider(
                  value: emotionIntensity,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: emotionIntensity.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      emotionIntensity = value;
                    });
                  },
                ),
                // Text for Intensity Value
                Text(
                  "Intensity: ${emotionIntensity.toInt()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                    height: 20), // Add spacing between slider and button

                // "Log Mood" Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: ElevatedButton(
                    onPressed:
                        selectedEmotionIndex == -1 ? null : submitEmotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedEmotionIndex == -1
                          ? const Color.fromARGB(
                              255, 176, 176, 176) // Disabled color
                          : const Color.fromARGB(
                              255, 0, 140, 2), // Active color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Log Mood",
                      style: TextStyle(
                        fontSize: 19,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
