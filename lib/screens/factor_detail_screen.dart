import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble_chart/bubble_chart.dart';
import 'dart:math';

class FactorDetailScreen extends StatefulWidget {
  final String factor;

  const FactorDetailScreen({Key? key, required this.factor}) : super(key: key);

  @override
  _FactorDetailScreenState createState() => _FactorDetailScreenState();
}

class _FactorDetailScreenState extends State<FactorDetailScreen> {
  bool isLoading = true;
  Map<String, int> counts = {};

  // Define unique colors for each factor
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
          await FirebaseFirestore.instance.collection('homehub').get();

      // Map Firestore fields to factors
      final fieldMap = {
        "Event": "events",
        "People": "people",
        "Health": null, // No data for Health
        "Environment": "environment_conditions",
        "Object": null, // No data for Object
      };

      final String? fieldName = fieldMap[widget.factor];
      if (fieldName == null) {
        setState(() {
          counts = {}; // Empty data for Health and Object
          isLoading = false;
        });
        return;
      }

      // Count occurrences of each item in the selected field
      final Map<String, int> tempCounts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data[fieldName] != null) {
          final List<dynamic> items = data[fieldName];

          // Filter out invalid or empty entries based on the factor
          for (var item in items) {
            if (item != null &&
                item is String &&
                item.isNotEmpty &&
                !_isInvalidEntry(item, widget.factor)) {
              tempCounts[item] = (tempCounts[item] ?? 0) + 1;
            }
          }
        }
      }

      // Sort by count and pick the top 6
      final sortedCounts = tempCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCounts = Map.fromEntries(sortedCounts.take(6));

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

  bool _isInvalidEntry(String entry, String factor) {
    // Define invalid entries for each factor
    const invalidEntries = {
      "People": ["No specific names of people mentioned in the text."],
      "Environment": [
        "No specific environment conditions mentioned in the text."
      ],
      "Locations": ["No specific locations mentioned in the text."]
    };

    return invalidEntries[factor]?.contains(entry) ?? false;
  }

  Widget _buildBubbleChart() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Define maximum bubble radius based on screen size
    const double minBubbleRadius = 30.0;
    final double maxBubbleRadius =
        (screenWidth < screenHeight ? screenWidth : screenHeight) / 4;

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
          color: factorColors[widget.factor] ??
              Colors.grey, // Assign unique color per factor
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: value * .2, // Proportional font size
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.factor),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : counts.isEmpty
              ? const Center(child: Text("No data available"))
              : Column(
                  children: [
                    Expanded(child: _buildBubbleChart()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                    )
                  ],
                ),
    );
  }
}
