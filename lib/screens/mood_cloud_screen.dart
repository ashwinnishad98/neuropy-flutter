import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'package:neuropy_app/screens/factor_detail_screen.dart';
import 'package:neuropy_app/screens/mood_detail_screen.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

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
      'label': 'Joy',
      'color': const Color.fromARGB(255, 237, 156, 25),
    },
    {
      'label': 'Trust',
      'color': const Color.fromARGB(255, 166, 194, 50),
    },
    {
      'label': 'Fear',
      'color': const Color.fromARGB(255, 56, 155, 78),
    },
    {
      'label': 'Surprise',
      'color': const Color.fromARGB(255, 38, 188, 159),
    },
    {
      'label': 'Sadness',
      'color': const Color.fromARGB(255, 62, 157, 245),
    },
    {
      'label': 'Disgust',
      'color': const Color.fromARGB(255, 120, 88, 255),
    },
    {
      'label': 'Anger',
      'color': const Color.fromARGB(255, 255, 92, 101),
    },
    {
      'label': 'Anticipation',
      'color': const Color.fromARGB(255, 252, 117, 87),
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
          await FirebaseFirestore.instance.collection('emotions').get();

      Map<String, int> counts = {};
      for (var bubble in bubbles) {
        counts[bubble['label']] = 0;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final emotion = data['emotion'] as String;
        if (counts.containsKey(emotion)) {
          counts[emotion] = (counts[emotion] ?? 0) + 1;
        }
      }

      setState(() {
        emotionCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching emotion counts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMoodView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate the maximum count for scaling
    final int maxCount = emotionCounts.values.isNotEmpty
        ? emotionCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;

    // Define size limits
    const double maxBubbleRadius = 80.0; // Maximum bubble radius
    const double minBubbleRadius = 20.0; // Minimum bubble radius

    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Calculate a scaling factor to ensure bubbles fit within the screen
    final double maxAllowedRadius =
        (screenWidth < screenHeight ? screenWidth : screenHeight) / 4 - 15;

    // Create child nodes for the bubble chart
    final List<BubbleNode> childNodes = bubbles.map((bubble) {
      final String label = bubble['label'];
      final int count = emotionCounts[label] ?? 0;

      // Apply logarithmic scaling for large counts
      double scaledValue = count > 0 ? (1 + (log(count) / log(maxCount))) : 0.5;

      // Scale bubble size between min and max radius
      double value =
          scaledValue * (maxBubbleRadius - minBubbleRadius) + minBubbleRadius;

      // Constrain value to fit within maxAllowedRadius
      value = value.clamp(minBubbleRadius, maxAllowedRadius);

      return BubbleNode.leaf(
        value: value,
        options: BubbleOptions(
          color: count == 0
              ? const Color.fromARGB(255, 169, 169, 169)
              : bubble['color'],
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MoodDetailScreen(
                      mood: label), // Navigate to MoodDetailScreen
                ),
              );
            },
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: value * .3, // Text size proportional to bubble size
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Center(
      child: BubbleChartLayout(
        children: childNodes,
        padding: 5,
        duration: const Duration(milliseconds: 500), // Animation duration
        radius: (node) => node.value * .8, // Adjusted scaling factor for radius
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood and Factor'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
