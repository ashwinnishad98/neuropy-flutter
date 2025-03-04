import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bubble_chart/bubble_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'emotion_wheel_screen.dart';
import 'mood_cloud_screen.dart';
import 'conversation_history.dart';
import '../models/mood_entry.dart';
import 'mood_graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodEntry? latestMoodEntry;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestMoodEntry();
  }

  Future<void> _fetchLatestMoodEntry() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Try both collection names to see if that's the issue
      final String collectionName = "homehub emotions";

      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      print("Query returned ${querySnapshot.docs.length} documents");

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        print("Found document with data: ${data.keys}");

        try {
          final entry = MoodEntry.fromMap(data);
          print(
              "Successfully parsed entry with transcript: ${entry.transcript.substring(0, min(20, entry.transcript.length))}...");

          setState(() {
            latestMoodEntry = entry;
          });
        } catch (parseError) {
          print("Error parsing document: $parseError");
          // Try to extract useful data even if full parsing fails
          setState(() {
            latestMoodEntry = MoodEntry(
              transcript: data['transcript'] ?? "Could not parse transcript",
              emotions: [],
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching latest mood entry: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning!";
    } else if (hour < 17) {
      return "Good Afternoon!";
    } else {
      return "Good Evening!";
    }
  }

  // Helper function to extract ~2 sentences from transcript
  String _formatTranscript(String transcript) {
    // Split by sentence-ending punctuation but preserve the punctuation
    final sentences = transcript.split(RegExp(r'(?<=[.!?])\s+'));

    if (sentences.length <= 2) {
      return transcript;
    }

    // Take first two sentences and add ellipsis with proper spacing
    return '${sentences[0]} ${sentences[1]}...';
  }

  // Format timestamp to human-readable time
  String _formatTime(DateTime timestamp) {
    return DateFormat('h:mma').format(timestamp).toLowerCase();
  }

  // Get color for emotion
  Color _getColorForEmotion(String emotion) {
    final Map<String, Color> emotionColors = {
      'Joy': const Color.fromARGB(255, 237, 156, 25),
      'Trust': const Color.fromARGB(255, 155, 61, 130),
      'Fear': const Color.fromARGB(255, 56, 155, 78),
      'Surprise': const Color.fromARGB(255, 38, 188, 159),
      'Sadness': const Color.fromARGB(255, 62, 157, 245),
      'Disgust': const Color.fromARGB(255, 120, 88, 255),
      'Anger': const Color.fromARGB(255, 255, 92, 101),
      'Anticipation': const Color.fromARGB(255, 252, 117, 87),
    };

    return emotionColors[emotion] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Look into your mood trends",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MoodGraphScreen()),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Mood Record",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text("View your mood insights!"),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Image.asset(
                            'assets/graph.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MoodCloudScreen()),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Factors Analysis",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: BubbleChartWidget(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConversationHistory()),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mood Journal",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : latestMoodEntry == null
                                ? const Text(
                                    "No journal entries yet.",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  )
                                : Text(
                                    _formatTranscript(
                                        latestMoodEntry!.transcript),
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        const SizedBox(height: 8),
                        isLoading || latestMoodEntry == null
                            ? const SizedBox()
                            : Row(
                                children: [
                                  // First filter out 'Unknown' emotions, then deduplicate, then take up to 3
                                  ...latestMoodEntry!.emotions
                                      .where((emotion) => 
                                          emotion['basic_emotion'] != null && 
                                          emotion['basic_emotion'] != 'Unknown' &&
                                          emotion['basic_emotion'].toString().isNotEmpty)
                                      // Create a new list with unique emotions by basic_emotion value
                                      .fold<List<Map<String, dynamic>>>([], (uniqueList, emotion) {
                                        if (!uniqueList.any((e) => e['basic_emotion'] == emotion['basic_emotion'])) {
                                          uniqueList.add(emotion);
                                        }
                                        return uniqueList;
                                      })
                                      .take(2)
                                      .map(
                                        (emotion) => Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Chip(
                                            label: Text(emotion['basic_emotion']),
                                            backgroundColor: _getColorForEmotion(emotion['basic_emotion']),
                                            labelStyle: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  const Spacer(),
                                  Text(_formatTime(latestMoodEntry!.timestamp),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EmotionWheelScreen()),
              );
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

class MoodRecordScreen extends StatelessWidget {
  const MoodRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Record')),
      body: Center(child: Image.asset('assets/graph.png')),
    );
  }
}

class BubbleChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> bubbles = [
      {
        'label': 'Joy',
        'color': const Color.fromARGB(255, 237, 156, 25),
        'value': 50,
      },
      {
        'label': 'Trust',
        'color': const Color.fromARGB(255, 155, 61, 130),
        'value': 40,
      },
      {
        'label': 'Fear',
        'color': const Color.fromARGB(255, 56, 155, 78),
        'value': 25,
      },
      {
        'label': 'Surprise',
        'color': const Color.fromARGB(255, 38, 188, 159),
        'value': 30,
      },
      {
        'label': 'Sadness',
        'color': const Color.fromARGB(255, 62, 157, 245),
        'value': 30,
      },
      {
        'label': 'Disgust',
        'color': const Color.fromARGB(255, 120, 88, 255),
        'value': 30,
      },
      {
        'label': 'Anger',
        'color': const Color.fromARGB(255, 255, 92, 101),
        'value': 35,
      },
      {
        'label': 'Anticipation',
        'color': const Color.fromARGB(255, 252, 117, 87),
        'value': 45,
      },
    ];

    final List<BubbleNode> childNodes = bubbles.map((bubble) {
      return BubbleNode.leaf(
        value: bubble['value'].toDouble(),
        options: BubbleOptions(
          color: bubble['color'],
          child: Center(
            child: Text(
              bubble['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: bubble['value'].toDouble() * 0.35,
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
        duration: const Duration(milliseconds: 500),
        radius: (node) => node.value * 0.8,
      ),
    );
  }
}
