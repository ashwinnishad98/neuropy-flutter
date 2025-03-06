import 'package:flutter/material.dart';
import 'package:neuropy_app/screens/mood_graph_screen.dart';
import '../widgets/emotion_wheel_painter.dart';
import '../services/firestore_service.dart';
import 'dart:math';
import '../models/emotion.dart';
import 'package:neuropy_app/screens/home_screen.dart';
import 'package:neuropy_app/screens/conversation_history.dart';
import '../utils/emotion_colors.dart';

class EmotionWheelScreen extends StatefulWidget {
  const EmotionWheelScreen({super.key});

  @override
  _EmotionWheelScreenState createState() => _EmotionWheelScreenState();
}

class _EmotionWheelScreenState extends State<EmotionWheelScreen>
    with TickerProviderStateMixin {
  double emotionIntensity = 1;
  final List<Emotion> emotions = [
    const Emotion(
      label: 'Happy',
      color: EmotionColors.joy,
      imagePath: 'assets/joy.png',
    ),
    const Emotion(
      label: 'Confident',
      color: EmotionColors.trust,
      imagePath: 'assets/trust.png',
    ),
    const Emotion(
      label: 'Anxious',
      color: EmotionColors.fear,
      imagePath: 'assets/fear.png',
    ),
    const Emotion(
      label: 'Shock',
      color: EmotionColors.surprise,
      imagePath: 'assets/surprise.png',
    ),
    const Emotion(
      label: 'Sad',
      color: EmotionColors.sadness,
      imagePath: 'assets/sadness.png',
    ),
    const Emotion(
      label: 'Disgust',
      color: EmotionColors.disgust,
      imagePath: 'assets/disgust.png',
    ),
    const Emotion(
      label: 'Annoyance',
      color: EmotionColors.anger,
      imagePath: 'assets/anger.png',
    ),
    const Emotion(
      label: 'Curiosity',
      color: EmotionColors.anticipation,
      imagePath: 'assets/anticipation.png',
    ),
  ];

  bool isImageVisible = false; // Controls image visibility for animation
  int selectedEmotionIndex = -1;

  // Tap animation controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Added for Entry Animation
  late AnimationController _entryController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Entry animation controller
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _rotationAnimation = Tween<double>(begin: -0.25, end: 0.0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void onTapDown(TapDownDetails details, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset touchPoint = details.localPosition;

    final double dx = touchPoint.dx - center.dx;
    final double dy = touchPoint.dy - center.dy;

    // Calculate distance from center to check if tap is within the wheel
    final double distance = sqrt(dx * dx + dy * dy);
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.45;

    // Only process taps that fall within the ring
    if (distance < innerRadius || distance > outerRadius) {
      return; // Tap outside the ring area
    }

    // Calculate angle but start from top (negative y-axis)
    // instead of right (positive x-axis)
    double angle = atan2(dy, dx) + pi / 2;

    if (angle < 0) angle += 2 * pi;

    final double anglePerSegment = (2 * pi) / emotions.length;
    final int tappedSegment =
        (angle / anglePerSegment).floor() % emotions.length;

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
        }
        // Always show image when selecting a new emotion
        isImageVisible = selectedEmotionIndex != -1;
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
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const MoodGraphScreen()));

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

  void _showAnalysisComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Coming Soon!'),
          content: const Text(
              'Analysis feature will be available in a future update.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 131, 229, 211),
              const Color.fromARGB(255, 208, 230, 247),
              const Color.fromARGB(255, 197, 185, 245),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text(
                  "How are you feeling now?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 75),

                SizedBox(
                  height: 360,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _opacityAnimation.value,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateZ(_rotationAnimation.value * pi * 2)
                              ..scale(_rotationAnimation.value < -0.05
                                  ? 0.8 +
                                      0.2 *
                                          (1 +
                                              (_rotationAnimation.value /
                                                  -0.25))
                                  : 1.0),
                            alignment: Alignment.center,
                            child: child,
                          ),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: GestureDetector(
                              onTapDown: (details) {
                                _animationController.forward();
                                onTapDown(details, const Size(410, 410));
                              },
                              onTapUp: (_) {
                                _animationController.reverse();
                              },
                              onTapCancel: () {
                                _animationController.reverse();
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    painter: EmotionWheelPainter(
                                      emotions,
                                      selectedEmotionIndex,
                                    ),
                                    child:
                                        const SizedBox(width: 400, height: 400),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: AnimatedCrossFade(
                                      crossFadeState: isImageVisible
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      firstChild: const SizedBox(),
                                      secondChild: selectedEmotionIndex != -1
                                          ? Image.asset(
                                              emotions[selectedEmotionIndex]
                                                  .imagePath,
                                              width: 122,
                                              height: 122,
                                            )
                                          : const SizedBox(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom controls section
                Column(
                  children: [
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
                              ? const Color.fromARGB(255, 176, 176, 176)
                              : const Color.fromARGB(255, 0, 140, 2),
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
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConversationHistory()),
              );
              break;
            case 3:
              _showAnalysisComingSoonDialog();
              break;
          }
        },
      ),
    );
  }
}
