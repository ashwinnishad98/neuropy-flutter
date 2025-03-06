import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'dart:math';
import '../utils/emotion_colors.dart';

class FactorDetailScreen extends StatefulWidget {
  final String factor;

  const FactorDetailScreen({Key? key, required this.factor}) : super(key: key);

  @override
  _FactorDetailScreenState createState() => _FactorDetailScreenState();
}

class _FactorDetailScreenState extends State<FactorDetailScreen> {
  bool isLoading = true;
  Map<String, int> counts = {};

  final Map<String, Color> factorColors = {
    "Event": Colors.blueAccent,
    "People": Colors.pinkAccent,
    "Health": Colors.greenAccent,
    "Environment": Colors.tealAccent,
    "Object": Colors.purpleAccent,
  };

  @override
  void initState() {
    super.initState();
    fetchFactorData();
  }

  Future<void> fetchFactorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('homehub emotions').get();

      // Map factor names to Firebase document structure keys
      final Map<String, String> factorToFirebaseKey = {
        "Event": "Events",
        "People": "People",
        "Health": "Health",
        "Environment": "Environment",
        "Object": "Objects",
      };

      final String firebaseKey =
          factorToFirebaseKey[widget.factor] ?? widget.factor;

      // Count occurrences of each item in the selected factor category
      final Map<String, int> tempCounts = {};

      // Process documents from the 'homehub emotions' collection
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if the document has associations
        if (data['associations'] is Map<String, dynamic>) {
          final associations = data['associations'] as Map<String, dynamic>;

          // Check if the factor exists in associations
          if (associations.containsKey(firebaseKey)) {
            final factorData =
                associations[firebaseKey] as Map<String, dynamic>;

            // Process each emotion's association with this factor
            factorData.forEach((emotion, itemList) {
              if (itemList is List) {
                // Count each item in the list
                for (var item in itemList) {
                  if (item is String && item.isNotEmpty) {
                    // Add emotion as context in brackets
                    String itemWithContext = "$item ($emotion)";
                    tempCounts[itemWithContext] =
                        (tempCounts[itemWithContext] ?? 0) + 1;
                  }
                }
              }
            });
          }
        }
      }

      // Sort by count and pick the top 10
      final sortedCounts = tempCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCounts = Map.fromEntries(sortedCounts.take(7));

      setState(() {
        counts = topCounts;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ${widget.factor} data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildBubbleChart() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    const double minBubbleRadius = 50.0;
    final double maxBubbleRadius =
        (screenWidth < screenHeight ? screenWidth : screenHeight) / 4;

    final bool allCountsSame =
        counts.values.every((count) => count == counts.values.first);

    // Get maximum and minimum counts for scaling
    final int maxCount =
        counts.values.isNotEmpty ? counts.values.reduce(max) : 1;
    final int minCount =
        counts.values.isNotEmpty ? counts.values.reduce(min) : 0;

    // Generate bubbles dynamically
    final List<BubbleNode> childNodes = counts.entries.map((entry) {
      final String label = entry.key;
      final int count = entry.value;

      double scaleFactor;
      if (allCountsSame || (maxCount - minCount <= 1)) {
        // If all counts are the same or very close, use more uniform sizes
        final int index = counts.keys.toList().indexOf(label);
        scaleFactor = 0.7 + (0.2 * index / max(1, counts.length - 1));
      } else {
        scaleFactor = 0.5 +
            (0.4 * sqrt((count - minCount) / max(1, maxCount - minCount)));
      }

      // Apply the scaling with clear min/max bounds
      double value =
          minBubbleRadius + (scaleFactor * (maxBubbleRadius - minBubbleRadius));

      // Extract emotion and get color
      String? emotion;
      final emotionMatch = RegExp(r'\((.*?)\)$').firstMatch(label);
      if (emotionMatch != null) {
        emotion = emotionMatch.group(1);
      }

      // Remove emotion part from label for display
      String displayLabel = label.replaceAll(RegExp(r'\s\([^)]+\)$'), '');

      // Truncate long text if necessary (with ellipsis)
      if (displayLabel.length > 15) {
        displayLabel = '${displayLabel.substring(0, 13)}...';
      }

      Color bubbleColor = (emotion != null)
          ? _getEmotionColor(emotion)
          : (factorColors[widget.factor] ?? Colors.grey);

      return BubbleNode.leaf(
        value: value,
        options: BubbleOptions(
          color: bubbleColor,
          child: Center(
            child: Text(
              displayLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: value * 0.2,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final double chartSize =
          min(constraints.maxWidth, constraints.maxHeight) * 0.9;

      return Center(
        child: SizedBox(
          width: chartSize,
          height: chartSize,
          child: BubbleChartLayout(
            children: childNodes,
            padding: 8,
            duration: const Duration(milliseconds: 500),
            radius: (node) => node.value * 0.6,
          ),
        ),
      );
    });
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return EmotionColors.joy;
      case 'trust':
        return EmotionColors.trust;
      case 'fear':
        return EmotionColors.fear;
      case 'surprise':
        return EmotionColors.surprise;
      case 'sadness':
        return EmotionColors.sadness;
      case 'disgust':
        return EmotionColors.disgust;
      case 'anger':
        return EmotionColors.anger;
      case 'anticipation':
        return EmotionColors.anticipation;
      default:
        return factorColors[widget.factor] ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const SizedBox(height: 48),

                // Title
                Center(
                  child: Text(
                    widget.factor,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bubble chart or loading indicator
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : counts.isEmpty
                          ? Center(
                              child: Text(
                                "No ${widget.factor} data found",
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : _buildBubbleChart(),
                ),
              ],
            ),

            // Back button overlay
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
