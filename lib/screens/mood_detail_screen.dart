import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'dart:math';
import '../utils/emotion_colors.dart';

class MoodDetailScreen extends StatefulWidget {
  final String mood;

  const MoodDetailScreen({Key? key, required this.mood}) : super(key: key);

  @override
  _MoodDetailScreenState createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen> {
  bool isLoading = true;
  Map<String, Map<String, int>> categorizedCounts = {};
  String? selectedFactor;
  String? errorMessage;
  int processedDocuments = 0;
  int matchedDocuments = 0;

  final Map<String, Color> moodColors = {
    'Joy': EmotionColors.joy,
    'Trust': EmotionColors.trust,
    'Fear': EmotionColors.fear,
    'Surprise': EmotionColors.surprise,
    'Sadness': EmotionColors.sadness,
    'Disgust': EmotionColors.disgust,
    'Anger': EmotionColors.anger,
    'Anticipation': EmotionColors.anticipation,
  };

  final Map<String, String> emotionDisplayNames = {
    'Joy': 'Happy',
    'Trust': 'Confident',
    'Fear': 'Anxious',
    'Surprise': 'Shock',
    'Sadness': 'Sad',
    'Disgust': 'Disgust',
    'Anger': 'Annoyance',
    'Anticipation': 'Curiosity',
  };

  String getEmotionDisplayName(String dbName) {
    return emotionDisplayNames[dbName] ?? dbName;
  }

  @override
  void initState() {
    super.initState();
    fetchMoodData();
  }

  Future<void> fetchMoodData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      processedDocuments = 0;
      matchedDocuments = 0;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('homehub emotions').get();

      final Map<String, Map<String, int>> tempCategorizedCounts = {
        'event': {},
        'people': {},
        'health': {},
        'environment': {},
        'object': {},
      };

      // Process each document
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        processedDocuments++;

        if (data['associations'] is Map<String, dynamic> &&
            data['emotions'] is Map<String, dynamic>) {
          final Map<String, dynamic> emotions = data['emotions'];

          bool documentHasMood = false;

          emotions.forEach((emotionName, emotionDetails) {
            if (emotionDetails is Map<String, dynamic> &&
                emotionDetails['basic_emotion'] == widget.mood) {
              documentHasMood = true;
            }
          });

          if (documentHasMood) {
            matchedDocuments++;

            // Process each factor category
            final Map<String, dynamic> associations = data['associations'];

            try {
              _processFactorCategory(
                  associations, 'Events', 'event', tempCategorizedCounts);
              _processFactorCategory(
                  associations, 'People', 'people', tempCategorizedCounts);
              _processFactorCategory(
                  associations, 'Health', 'health', tempCategorizedCounts);
              _processFactorCategory(associations, 'Environment', 'environment',
                  tempCategorizedCounts);
              _processFactorCategory(
                  associations, 'Objects', 'object', tempCategorizedCounts);
            } catch (e) {
              print("Error processing document: $e");
            }
          }
        }
      }

      setState(() {
        categorizedCounts = tempCategorizedCounts;
        isLoading = false;

        // If no matches were found, set an error message
        if (matchedDocuments == 0) {
          errorMessage =
              "No documents found containing ${widget.mood} emotion.";
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  // Helper method to process a factor category with better error handling
  void _processFactorCategory(
      Map<String, dynamic> associations,
      String firebaseKey,
      String localKey,
      Map<String, Map<String, int>> tempCounts) {
    if (!associations.containsKey(firebaseKey)) {
      return;
    }

    // Get the category map (e.g., Events, People, etc.)
    var categoryMap = associations[firebaseKey];
    if (!(categoryMap is Map<String, dynamic>)) {
      return;
    }

    // Check if our specific mood exists in this category
    if (!categoryMap.containsKey(widget.mood)) {
      return;
    }

    // Get the list of items for this mood
    var itemsList = categoryMap[widget.mood];
    if (!(itemsList is List)) {
      return;
    }

    // Process each item in the list
    for (var item in itemsList) {
      if (item is String && item.isNotEmpty) {
        tempCounts[localKey]![item] = (tempCounts[localKey]![item] ?? 0) + 1;
      }
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
    Map<String, int> allCounts = selectedFactor == null
        ? _getAllCounts()
        : categorizedCounts[selectedFactor!] ?? {};

    // Sort items by count in descending order and take top 10
    final Map<String, int> counts = _getTop10Counts(allCounts);

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
                fontSize: value * 0.22,
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

  // Helper method to get the top 10 items by count
  Map<String, int> _getTop10Counts(Map<String, int> allCounts) {
    // Convert map entries to a list
    final entries = allCounts.entries.toList();

    // Sort the entries by count (value) in descending order
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Take the top 10 entries (or fewer if there aren't 10)
    final topEntries = entries.take(10).toList();

    // Convert back to a map
    return Map.fromEntries(topEntries);
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
      {'label': 'Environment', 'key': 'environment'},
      {'label': 'Objects', 'key': 'object'},
      {'label': 'People', 'key': 'people'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height / 3,
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
              child: ListView.builder(
                itemCount: factors.length,
                itemBuilder: (context, index) {
                  final factor = factors[index];
                  final bool isSelected = selectedFactor == factor['key'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFactor = isSelected ? null : factor['key'];
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
      body: SafeArea(
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchMoodData,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : _isEmpty(categorizedCounts)
                        ? Center(
                            child: Text(
                              "No factors found for ${getEmotionDisplayName(widget.mood)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : Column(
                            children: [
                              const SizedBox(height: 48),
                              Center(
                                child: Text(
                                  getEmotionDisplayName(widget.mood),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(child: _buildBubbleChart()),
                              _buildFactorChips(),
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

  bool _isEmpty(Map<String, Map<String, int>> categorizedCounts) {
    int totalItems = 0;
    categorizedCounts.forEach((_, items) {
      totalItems += items.length;
    });
    return totalItems == 0;
  }
}
