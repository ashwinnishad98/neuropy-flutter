import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'package:neuropy_app/screens/factor_detail_screen.dart';
import 'package:neuropy_app/screens/mood_detail_screen.dart';

// Custom widget for animating bubbles
class FloatingBubble extends StatefulWidget {
  final Widget child;
  final double intensity; // Controls how much the bubble moves

  const FloatingBubble({
    Key? key,
    required this.child,
    this.intensity = 2.0,
  }) : super(key: key);

  @override
  _FloatingBubbleState createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  
  // Create a random offset for each bubble to make them move asynchronously
  final double _randomOffset = Random().nextDouble() * 2 * pi;

  @override
  void initState() {
    super.initState();
    
    // Create an animation controller with a longer duration for slow, gentle movement
    _controller = AnimationController(
      duration: Duration(milliseconds: 3000 + Random().nextInt(2000)), // Random duration for variety
      vsync: this,
    )..repeat(reverse: true); // Automatically reverse and repeat

    // Create a curved animation that moves slightly up and down
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, -0.01 * widget.intensity),
      end: Offset(0, 0.01 * widget.intensity),
    ).animate(CurvedAnimation(
      parent: _controller,
      // Use a sine wave curve for smooth, natural movement
      curve: Curves.elasticInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply a slight delay based on random offset to make bubbles move asynchronously
    Future.delayed(Duration(milliseconds: (_randomOffset * 300).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });

    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

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
      'color': const Color.fromARGB(255, 155, 61, 130),
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

    // Calculate the maximum and minimum counts
    final int maxCount = emotionCounts.values.isNotEmpty
        ? emotionCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;
    
    final int minCount = emotionCounts.values.isNotEmpty
        ? emotionCounts.values.reduce((a, b) => a < b ? a : b)
        : 0;

    // Much larger gap between min and max radius for better visual differentiation
    const double maxBubbleRadius = 120.0; // Increased maximum radius
    const double minBubbleRadius = 35.0; // Decreased minimum radius

    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // More conservative max allowed radius
    final double maxAllowedRadius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 4;

    // Create child nodes for the bubble chart
    final List<BubbleNode> childNodes = bubbles.map((bubble) {
      final String label = bubble['label'];
      final int count = emotionCounts[label] ?? 0;

      // Enhanced scaling logic for small counts
      double scaledValue;
      
      if (maxCount == minCount) {
        // If all counts are equal, use a middle value
        scaledValue = 0.7;
      } else if (count == 0) {
        // Special case for zero counts
        scaledValue = 0.2; // Make zero counts even smaller
      } else {
        // For very small ranges (like 1-4), we need a more aggressive approach
        
        // Start with a higher base for non-zero values
        double baseValue = 0.3; 
        
        // Add an amplified proportion of the range
        // This creates bigger jumps between values
        double amplifier = 1.5; // Amplification factor
        double proportion = (count - minCount) / max(1, maxCount - minCount);
        
        // Apply amplified scaling
        scaledValue = baseValue + (0.6 * proportion * amplifier);
        
        // Clamp to ensure we don't exceed 1.0
        scaledValue = min(1.0, scaledValue);
      }

      // Scale bubble size between min and max radius
      double value = scaledValue * (maxBubbleRadius - minBubbleRadius) + minBubbleRadius;
      
      // Constrain value to fit within maxAllowedRadius
      value = value.clamp(minBubbleRadius, maxAllowedRadius);
      
      // Calculate animation intensity based on bubble size
      // Smaller bubbles move more, larger bubbles move less
      double animationIntensity = 1.0 - (value - minBubbleRadius) / (maxBubbleRadius - minBubbleRadius);
      animationIntensity = animationIntensity * 1.5 + 0.5; // Scale between 0.5 and 2.0

      return BubbleNode.leaf(
        value: value,
        options: BubbleOptions(
          color: count == 0
              ? const Color.fromARGB(255, 169, 169, 169)
              : bubble['color'],
          child: FloatingBubble(
            intensity: animationIntensity,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MoodDetailScreen(mood: label),
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
                    fontSize: value * 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Center(
      child: Container(
        child: BubbleChartLayout(
          children: childNodes,
          padding: 5,
          duration: const Duration(milliseconds: 500),
          radius: (node) => node.value * 0.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood and Factor'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 224, 224, 224),
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
