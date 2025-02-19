import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
          .collection('homehub')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        conversations = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'timestamp': data['timestamp'],
            'transcription': data['transcription'],
            'emotions': data['emotions'],
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

  Widget buildConversationCard(Map<String, dynamic> conversation) {
    final timestamp = conversation['timestamp'] as Timestamp;
    final transcription = conversation['transcription'] as String;
    final emotions = conversation['emotions'] as List<dynamic>;

    return Container(
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
            '"' + transcription.split(' ').take(20).join(' ') + '..."',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8.0,
                children: emotions.map<Widget>((emotionWithIntensity) {
                  // Extract only the emotion part (e.g., "Joy" from "Joy (High)")
                  final emotion = emotionWithIntensity.split(' (')[0];
                  return Chip(
                    label: Text(
                      emotion,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: getEmotionColor(emotionWithIntensity),
                  );
                }).toList(),
              ),
              Text(
                DateFormat('MMM dd, yyyy – hh:mm a').format(timestamp.toDate()),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color getEmotionColor(String emotionWithIntensity) {
    // Extract only the emotion part by splitting at the space before '('
    final emotion = emotionWithIntensity.split(' (')[0].toLowerCase();

    switch (emotion) {
      case 'joy':
        return const Color.fromARGB(255, 237, 156, 25);
      case 'trust':
        return const Color.fromARGB(255, 166, 194, 50);
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
      backgroundColor:
          const Color.fromARGB(255, 224, 224, 224), // Updated background color
      appBar: AppBar(
        title: const Text('Conversation History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune), // Filter icon
            onPressed: () {
              // Add functionality for the filter button here
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
    );
  }
}
