import 'package:flutter/material.dart';
import 'package:neuropy_app/screens/mood_graph_screen.dart';
import '../widgets/emotion_wheel_painter.dart';
import '../widgets/emotion_center_image.dart';
import '../services/firestore_service.dart';
import 'dart:math';
import '../models/emotion.dart';
import 'package:neuropy_app/screens/home_screen.dart';
import 'package:neuropy_app/screens/conversation_history.dart';

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
      color: Color.fromARGB(255, 155, 61, 130),
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

    // First fade out the current image
    setState(() {
      isImageVisible = false;
    });

    // After the fade-out completes, update the selected emotion
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        // If we tap the same segment twice, deselect it
        if (tappedSegment == selectedEmotionIndex) {
          selectedEmotionIndex = -1;
        } else {
          selectedEmotionIndex = tappedSegment;
          // Only fade in if we selected a new emotion
          isImageVisible = true;
        }
      });
    });
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MoodGraphScreen()));

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
            // Fixed height for top section
            const SizedBox(height: 30),
            const Text(
              "How are you feeling now?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Fixed size container for the wheel instead of Expanded
            SizedBox(
              height: 360, // Fixed height for wheel
              child: Center(
                child: GestureDetector(
                  onTapDown: (details) =>
                      onTapDown(details, const Size(400, 400)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter:
                            EmotionWheelPainter(emotions, selectedEmotionIndex),
                        child: const SizedBox(width: 400, height: 400),
                      ),
                      // Create a container for consistent positioning
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: AnimatedCrossFade(
                          crossFadeState: isImageVisible 
                              ? CrossFadeState.showSecond 
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                          firstChild: const SizedBox(), // Empty widget when no image
                          secondChild: selectedEmotionIndex != -1
                              ? Image.asset(
                                  emotions[selectedEmotionIndex].imagePath,
                                  width: 120,
                                  height: 120,
                                )
                              : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Flexible spacer that will push the slider down
            const Spacer(),
            
            // Bottom controls section
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
                const SizedBox(height: 20),

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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Set to 1 for the Log Mood tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Log Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 1:
              // Already on EmotionWheelScreen, no navigation needed
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConversationHistory()),
              );
              break;
            case 3:
              // No functionality for Analysis button yet
              break;
          }
        },
      ),
    );
  }
}
