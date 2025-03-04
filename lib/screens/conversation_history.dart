import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'conversation_detail_screen.dart';
import 'package:neuropy_app/screens/home_screen.dart';
import 'package:neuropy_app/screens/emotion_wheel_screen.dart';

class ConversationHistory extends StatefulWidget {
  const ConversationHistory({super.key});

  @override
  _ConversationHistoryState createState() => _ConversationHistoryState();
}

class _ConversationHistoryState extends State<ConversationHistory> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final DateTime startDate = selectedDate.subtract(const Duration(days: 7));
      final DateTime endDate = selectedDate;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('homehub emotions') // Updated collection name
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        conversations = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Extract emotions from the new structure
          List<Map<String, dynamic>> extractedEmotions = [];
          Map<String, dynamic>? emotionsMap =
              data['emotions'] as Map<String, dynamic>?;

          if (emotionsMap != null) {
            emotionsMap.forEach((key, value) {
              if (value is Map<String, dynamic> &&
                  value.containsKey('basic_emotion') &&
                  value['basic_emotion'] != null &&
                  value['basic_emotion'] != 'Unknown') {
                extractedEmotions.add({
                  'emotion_name': key,
                  'basic_emotion': value['basic_emotion'],
                  'score': value['score'] ?? '0'
                });
              }
            });
          }

          // Extract associations for detail view
          Map<String, dynamic> associations = {};
          if (data['associations'] is Map<String, dynamic>) {
            associations = data['associations'] as Map<String, dynamic>;
          }

          return {
            'timestamp': data['timestamp'],
            'transcript': data['transcript'] ??
                '', // Updated field name from transcription
            'emotions': extractedEmotions,
            'associations': associations,
            'emotional_analysis': data['emotional_analysis'] ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void changeWeek(int offset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: offset * 7));
    });
    fetchConversations();
  }

  Widget buildCalendar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => changeWeek(-1),
        ),
        Text(
          '${DateFormat('MMM dd').format(selectedDate.subtract(const Duration(days: 7)))} - ${DateFormat('MMM dd').format(selectedDate)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: selectedDate.isBefore(DateTime.now())
              ? () => changeWeek(1)
              : null,
        ),
      ],
    );
  }

  // Helper function to extract first two sentences
  String _formatTranscript(String transcript) {
    // Split by sentence-ending punctuation but preserve the punctuation
    final sentences = transcript.split(RegExp(r'(?<=[.!?])\s+'));

    if (sentences.length <= 2) {
      return transcript;
    }

    // Take first two sentences and add ellipsis
    return '${sentences[0]} ${sentences[1]}...';
  }

  Widget buildConversationCard(Map<String, dynamic> conversation) {
    final timestamp = conversation['timestamp'] as Timestamp;
    final transcript = conversation['transcript'] as String;
    final emotions = (conversation['emotions'] ?? []) as List<dynamic>;

    // Process emotions to remove duplicates and "Unknown" values
    final Set<String> uniqueEmotions = {};
    final List<Map<String, dynamic>> filteredEmotions = [];

    // Filter out duplicates and "Unknown" emotions
    for (var emotion in emotions) {
      final basicEmotion = emotion['basic_emotion'];
      if (basicEmotion != null &&
          basicEmotion != 'Unknown' &&
          !uniqueEmotions.contains(basicEmotion)) {
        uniqueEmotions.add(basicEmotion);
        filteredEmotions.add(emotion);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversation: conversation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${_formatTranscript(transcript)}"',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: filteredEmotions
                        .take(2) // Limit to 2 emotions
                        .map<Widget>((emotion) {
                      final basicEmotion = emotion['basic_emotion'];
                      return Chip(
                        label: Text(
                          basicEmotion,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                        backgroundColor: getEmotionColor(basicEmotion),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy – hh:mm a')
                      .format(timestamp.toDate()),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color getEmotionColor(String emotion) {
    // Convert to lowercase for case-insensitive comparison
    final String lowerEmotion = emotion.toLowerCase();

    switch (lowerEmotion) {
      case 'joy':
        return const Color.fromARGB(255, 237, 156, 25);
      case 'trust':
        return const Color.fromARGB(255, 155, 61, 130);
      case 'fear':
        return const Color.fromARGB(255, 56, 155, 78);
      case 'surprise':
        return const Color.fromARGB(255, 38, 188, 159);
      case 'sadness':
        return const Color.fromARGB(255, 62, 157, 245);
      case 'disgust':
        return const Color.fromARGB(255, 120, 88, 255);
      case 'anger':
        return const Color.fromARGB(255, 255, 92, 101);
      case 'anticipation':
        return const Color.fromARGB(255, 252, 117, 87);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 224, 224),
      appBar: AppBar(
        title: const Text('Conversation History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Filter Conversations'),
                    content: const Text('Filter options can be added here.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: buildCalendar(),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                    ? const Center(
                        child: Text('No conversations found for this week.'),
                      )
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) =>
                            buildConversationCard(conversations[index]),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Set to 2 for Journal tab
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
              // Already on ConversationHistory, no navigation needed
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
