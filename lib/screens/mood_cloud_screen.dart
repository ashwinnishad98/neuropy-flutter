import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'package:neuropy_app/screens/factor_detail_screen.dart';
import 'package:neuropy_app/screens/mood_detail_screen.dart';
import '../utils/emotion_colors.dart';

class MoodCloudScreen extends StatefulWidget {
  const MoodCloudScreen({super.key});

  @override
  _MoodCloudScreenState createState() => _MoodCloudScreenState();
}

class _MoodCloudScreenState extends State<MoodCloudScreen> {
  int selectedToggleIndex = 0;
  Map<String, int> emotionCounts = {};
  bool isLoading = true;

  final List<Map<String, dynamic>> bubbles = [
    {
      'label': 'Happy',
      'dbName': 'Joy',
      'color': EmotionColors.joy,
    },
    {
      'label': 'Trust',
      'dbName': 'Trust',
      'color': EmotionColors.trust,
    },
    {
      'label': 'Fear',
      'dbName': 'Fear',
      'color': EmotionColors.fear,
    },
    {
      'label': 'Surprise',
      'dbName': 'Surprise',
      'color': EmotionColors.surprise,
    },
    {
      'label': 'Sadness',
      'dbName': 'Sadness',
      'color': EmotionColors.sadness,
    },
    {
      'label': 'Disgust',
      'dbName': 'Disgust',
      'color': EmotionColors.disgust,
    },
    {
      'label': 'Anger',
      'dbName': 'Anger',
      'color': EmotionColors.anger,
    },
    {
      'label': 'Curiosity',
      'dbName': 'Anticipation',
      'color': EmotionColors.anticipation,
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchEmotionCounts();
  }

  Future<void> fetchEmotionCounts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('homehub emotions').get();

      Map<String, int> counts = {};
      // Initialize counts for all emotions to 0, using dbName for the keys
      for (var bubble in bubbles) {
        counts[bubble['dbName']] = 0;
      }

      // Process the documents
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if 'emotions' exists in the document
        if (data.containsKey('emotions')) {
          final emotions = data['emotions'];

          if (emotions is Map<String, dynamic>) {
            emotions.forEach((key, value) {
              if (value is Map<String, dynamic> &&
                  value.containsKey('basic_emotion') &&
                  value['basic_emotion'] != null &&
                  value['basic_emotion'] != 'Unknown') {
                final String basicEmotion = value['basic_emotion'];
                // Increment count for this emotion
                if (counts.containsKey(basicEmotion)) {
                  counts[basicEmotion] = (counts[basicEmotion] ?? 0) + 1;
                }
              }
            });
          } else if (emotions is List<dynamic>) {
            for (var emotion in emotions) {
              if (emotion is Map<String, dynamic> &&
                  emotion.containsKey('basic_emotion') &&
                  emotion['basic_emotion'] != null &&
                  emotion['basic_emotion'] != 'Unknown') {
                final String basicEmotion = emotion['basic_emotion'];
                // Increment count for this emotion
                if (counts.containsKey(basicEmotion)) {
                  counts[basicEmotion] = (counts[basicEmotion] ?? 0) + 1;
                }
              }
            }
          }
        }
      }

      setState(() {
        emotionCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToMoodDetail(String dbName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodDetailScreen(mood: dbName),
      ),
    );
  }

  Widget _buildMoodView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate the maximum and minimum counts
    final int maxCount = emotionCounts.values.isNotEmpty
        ? emotionCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;

    final int minCount = emotionCounts.values.isNotEmpty
        ? emotionCounts.values.reduce((a, b) => a < b ? a : b)
        : 0;

    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Calculate available space for the chart area
    final double chartAreaSize = min(screenWidth, screenHeight - 160);

    final double baseMinBubbleRadius = chartAreaSize / 9;
    final double baseMaxBubbleRadius = chartAreaSize / 3.5;

    // Count number of non-zero emotions to help with spacing
    final int activeEmotionCount =
        emotionCounts.values.where((count) => count > 0).length;

    // Create child nodes for the bubble chart
    final List<BubbleNode> childNodes = bubbles.map((bubble) {
      final String displayLabel = bubble['label'];
      final String dbName =
          bubble['dbName']; // Get the database name to look up counts
      final int count = emotionCounts[dbName] ?? 0;

      // Calculate scaled value between 0.0 and 1.0
      double scaledValue;

      // Special case: if all counts are the same or there's only one non-zero count
      if (maxCount == minCount || activeEmotionCount <= 1) {
        if (count == 0) {
          scaledValue = 0.35;
        } else {
          scaledValue = 0.80;
        }
      }
      // Normal case: scale based on counts with enhanced differentiation
      else {
        if (count == 0) {
          scaledValue = 0.35;
        } else {
          double normalizedCount =
              (count - minCount) / max(1.0, maxCount - minCount);
          scaledValue = 0.42 + (0.5 * sqrt(normalizedCount));
        }
      }

      // Apply final radius calculation
      double value = baseMinBubbleRadius +
          (scaledValue * (baseMaxBubbleRadius - baseMinBubbleRadius));

      return BubbleNode.leaf(
        value: value,
        options: BubbleOptions(
          color: count == 0
              ? const Color.fromARGB(255, 169, 169, 169).withOpacity(0.7)
              : bubble['color'],
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(value),
              onTap: () => _navigateToMoodDetail(dbName),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Center(
                child: Text(
                  displayLabel, // Use display label for showing on screen
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: value * 0.22,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      return Center(
        child: SizedBox(
          width: chartAreaSize,
          height: chartAreaSize,
          child: BubbleChartLayout(
            children: childNodes,
            padding: 9,
            duration: const Duration(milliseconds: 500),
            radius: (node) => node.value * 0.57,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 190, 246, 236),
              Color.fromARGB(255, 214, 231, 246),
              Color.fromARGB(255, 216, 207, 250),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedToggleIndex = 0;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedToggleIndex == 0
                              ? Colors.black
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(20)),
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        child: Text(
                          "Mood",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedToggleIndex == 0
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedToggleIndex = 1;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedToggleIndex == 1
                              ? Colors.black
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(20)),
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        child: Text(
                          "Factor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedToggleIndex == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedToggleIndex == 0
                    ? _buildMoodView()
                    : _buildFactorView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactorView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildFactorTile(Icons.work, "Event"),
        _buildFactorTile(Icons.people, "People"),
        _buildFactorTile(Icons.health_and_safety, "Health"),
        _buildFactorTile(Icons.nature, "Environment"),
        _buildFactorTile(Icons.category, "Object"),
      ],
    );
  }

  Widget _buildFactorTile(IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FactorDetailScreen(factor: title),
            ),
          );
        },
      ),
    );
  }
}
