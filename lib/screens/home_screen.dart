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
import '../utils/emotion_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodEntry? latestMoodEntry;
  bool isLoading = true;

  // Map for converting database emotion names to display names
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
      final String collectionName = "homehub emotions";

      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();

        try {
          final entry = MoodEntry.fromMap(data);
          print(
              "Successfully parsed entry with transcript: ${entry.transcript.substring(0, min(20, entry.transcript.length))}...");

          setState(() {
            latestMoodEntry = entry;
          });
        } catch (parseError) {
          print("Error parsing document: $parseError");
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
    final sentences = transcript.split(RegExp(r'(?<=[.!?])\s+'));

    if (sentences.length <= 2) {
      return transcript;
    }

    return '${sentences[0]} ${sentences[1]}...';
  }

  // Format timestamp to human-readable time
  String _formatTime(DateTime timestamp) {
    return DateFormat('h:mma').format(timestamp).toLowerCase();
  }

  Color _getColorForEmotion(String emotion) {
    return EmotionColors.getColor(emotion);
  }

// New helper function to map emotion names for display
  String _getDisplayEmotionName(String emotion) {
    return emotionDisplayNames[emotion] ?? emotion;
  }

  Widget buildSoftCard({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(23)),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // Method to show the "Analysis coming soon" popup
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  buildSoftCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MoodGraphScreen()),
                      );
                    },
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 16),
                  buildSoftCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MoodCloudScreen()),
                      );
                    },
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
                  const SizedBox(height: 16),
                  buildSoftCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ConversationHistory()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
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
                                    ...latestMoodEntry!.emotions
                                        .where((emotion) =>
                                            emotion['basic_emotion'] != null &&
                                            emotion['basic_emotion'] !=
                                                'Unknown' &&
                                            emotion['basic_emotion']
                                                .toString()
                                                .isNotEmpty)
                                        .fold<List<Map<String, dynamic>>>([],
                                            (uniqueList, emotion) {
                                          if (!uniqueList.any((e) =>
                                              e['basic_emotion'] ==
                                              emotion['basic_emotion'])) {
                                            uniqueList.add(emotion);
                                          }
                                          return uniqueList;
                                        })
                                        .take(2)
                                        .map(
                                          (emotion) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Chip(
                                              label: Text(
                                                  _getDisplayEmotionName(
                                                      emotion[
                                                          'basic_emotion'])),
                                              backgroundColor:
                                                  _getColorForEmotion(
                                                      emotion['basic_emotion']),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    const Spacer(),
                                    Text(
                                        _formatTime(latestMoodEntry!.timestamp),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              _showAnalysisComingSoonDialog();
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
        'label': 'Happy',
        'color': EmotionColors.joy,
        'value': 39,
      },
      {
        'label': 'Confident',
        'color': EmotionColors.trust,
        'value': 48,
      },
      {
        'label': 'Anxious',
        'color': EmotionColors.fear,
        'value': 31,
      },
      {
        'label': 'Shock',
        'color': EmotionColors.surprise,
        'value': 25,
      },
      {
        'label': 'Sad',
        'color': EmotionColors.sadness,
        'value': 33,
      },
      {
        'label': 'Disgust',
        'color': EmotionColors.disgust,
        'value': 37,
      },
      {
        'label': 'Annoyance',
        'color': EmotionColors.anger,
        'value': 43,
      },
      {
        'label': 'Curiosity',
        'color': EmotionColors.anticipation,
        'value': 41,
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
                fontSize: (bubble['label'] == 'Annoyance' ||
                        bubble['label'] == 'Confident')
                    ? bubble['value'].toDouble() * 0.27
                    : bubble['value'].toDouble() * 0.32,
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
