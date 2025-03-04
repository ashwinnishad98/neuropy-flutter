import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'dart:math';

class MoodDetailScreen extends StatefulWidget {
  final String mood;

  const MoodDetailScreen({Key? key, required this.mood}) : super(key: key);

  @override
  _MoodDetailScreenState createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen> {
  bool isLoading = true;
  Map<String, Map<String, int>> categorizedCounts =
      {}; // Categorized counts for each factor
  String? selectedFactor; // Currently selected factor (e.g., "event", "people")

  // Define unique colors for each mood
  final Map<String, Color> moodColors = {
    'Joy': const Color.fromARGB(255, 237, 156, 25),
    'Trust': const Color.fromARGB(255, 155, 61, 130),
    'Fear': const Color.fromARGB(255, 56, 155, 78),
    'Surprise': const Color.fromARGB(255, 38, 188, 159),
    'Sadness': const Color.fromARGB(255, 62, 157, 245),
    'Disgust': const Color.fromARGB(255, 120, 88, 255),
    'Anger': const Color.fromARGB(255, 255, 92, 101),
    'Anticipation': const Color.fromARGB(255, 252, 117, 87),
  };

  @override
  void initState() {
    super.initState();
    fetchMoodData();
  }

  Future<void> fetchMoodData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('homehub').get();

      // Initialize categorized counts
      final Map<String, Map<String, int>> tempCategorizedCounts = {
        'event': {},
        'people': {},
        'health': {}, // Empty for now
        'environment': {},
        'object': {}, // Empty for now
        'locations': {},
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> emotions = data['emotions'] ?? [];

        // Check if the record matches the selected mood
        if (emotions.any((emotion) => emotion.startsWith(widget.mood))) {
          // Count events
          if (data['events'] != null) {
            for (var event in data['events']) {
              if (event != null && event is String && event.isNotEmpty) {
                tempCategorizedCounts['event']![event] =
                    (tempCategorizedCounts['event']![event] ?? 0) + 1;
              }
            }
          }

          // Count people
          if (data['people'] != null) {
            for (var person in data['people']) {
              if (person != null &&
                  person is String &&
                  person.isNotEmpty &&
                  person !=
                      "No specific names of people mentioned in the text.") {
                tempCategorizedCounts['people']![person] =
                    (tempCategorizedCounts['people']![person] ?? 0) + 1;
              }
            }
          }

          // Count environment_conditions
          if (data['environment_conditions'] != null) {
            for (var condition in data['environment_conditions']) {
              if (condition != null &&
                  condition is String &&
                  condition.isNotEmpty &&
                  condition !=
                      "No specific environment conditions mentioned in the text.") {
                tempCategorizedCounts['environment']![condition] =
                    (tempCategorizedCounts['environment']![condition] ?? 0) + 1;
              }
            }
          }

          // Count locations
          if (data['locations'] != null) {
            for (var location in data['locations']) {
              if (location != null &&
                  location is String &&
                  location.isNotEmpty &&
                  location != "No specific locations mentioned in the text.") {
                tempCategorizedCounts['locations']![location] =
                    (tempCategorizedCounts['locations']![location] ?? 0) + 1;
              }
            }
          }

          // Count Health
          if (data['health'] != null) {
            for (var health in data['health']) {
              if (health != null &&
                  health is String &&
                  health.isNotEmpty &&
                  health !=
                      "No specific health conditions mentioned in the text.") {
                tempCategorizedCounts['health']![health] =
                    (tempCategorizedCounts['health']![health] ?? 0) + 1;
              }
            }
          }

          // Count Object
          if (data['object'] != null) {
            for (var object in data['object']) {
              if (object != null &&
                  object is String &&
                  object.isNotEmpty &&
                  object !=
                      "No specific object conditions mentioned in the text.") {
                tempCategorizedCounts['object']![object] =
                    (tempCategorizedCounts['object']![object] ?? 0) + 1;
              }
            }
          }
        }
      }

      setState(() {
        categorizedCounts = tempCategorizedCounts;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ${widget.mood} data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildBubbleChart() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Define maximum bubble radius based on screen size
    const double minBubbleRadius = 30.0;
    final double maxBubbleRadius =
        (screenWidth < screenHeight ? screenWidth : screenHeight) / 4 - 25;

    // Get counts for the selected factor or all factors if none is selected
    final Map<String, int> counts = selectedFactor == null
        ? _getAllCounts()
        : categorizedCounts[selectedFactor!] ?? {};

    // Check if there are no bubbles to display and show a message instead
    if (counts.isEmpty && selectedFactor != null) {
      String factorTemp = selectedFactor != null
          ? selectedFactor![0].toUpperCase() + selectedFactor!.substring(1)
          : '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No ${factorTemp} factors found for this mood.'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
      return const SizedBox(); // Return an empty widget to avoid rendering errors
    }

    // Get maximum count for scaling
    final int maxCount =
        counts.values.isNotEmpty ? counts.values.reduce(max) : 1;

    // Generate bubbles dynamically
    final List<BubbleNode> childNodes = counts.entries.map((entry) {
      final String label = entry.key;
      final int count = entry.value;

      // Scale bubble size between min and max radius
      double value = (count / maxCount * (maxBubbleRadius - minBubbleRadius)) +
          minBubbleRadius;

      return BubbleNode.leaf(
        value: value,
        options: BubbleOptions(
          color: moodColors[widget.mood] ?? Colors.grey,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: value * .2,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Center(
      child: BubbleChartLayout(
        children: childNodes,
        padding: 10,
        duration: const Duration(milliseconds: 500),
        radius: (node) => node.value * .8,
      ),
    );
  }

  Map<String, int> _getAllCounts() {
    final Map<String, int> allCounts = {};
    categorizedCounts.forEach((_, counts) => allCounts.addAll(counts));
    return allCounts;
  }

  int _getFactorCount(String key) {
    final counts = categorizedCounts[key] ?? {};
    return counts.values.fold(0, (sum, count) => sum + count);
  }

  Widget _buildFactorChips() {
    final factors = [
      {'label': 'Life Event', 'key': 'event'},
      {'label': 'Health', 'key': 'health'},
      {'label': 'Weather', 'key': 'environment'},
      {'label': 'Objects', 'key': 'object'},
      {'label': 'People', 'key': 'people'},
      {'label': 'Locations', 'key': 'locations'}
    ];

    return Container(
      height:
          MediaQuery.of(context).size.height / 3, // Bottom third of the screen
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Factors",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Ensure the ListView is scrollable
              child: ListView.builder(
                itemCount: factors.length,
                itemBuilder: (context, index) {
                  final factor = factors[index];
                  final bool isSelected = selectedFactor == factor['key'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFactor = isSelected
                            ? null
                            : factor['key']; // Toggle selection
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? moodColors[widget.mood] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                isSelected ? Colors.transparent : Colors.black),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            factor['label'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            "${_getFactorCount(factor['key'] ?? '')} times",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
        title: Text(widget.mood),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categorizedCounts.isEmpty
              ? const Center(child: Text("No data available"))
              : Column(
                  children: [
                    Expanded(child: _buildBubbleChart()),
                    _buildFactorChips(), // Add chips below the bubble chart
                  ],
                ),
    );
  }
}
