import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'conversation_detail_screen.dart';
import 'package:neuropy_app/screens/home_screen.dart';
import 'package:neuropy_app/screens/emotion_wheel_screen.dart';
import '../utils/emotion_colors.dart';

class ConversationHistory extends StatefulWidget {
  const ConversationHistory({super.key});

  @override
  _ConversationHistoryState createState() => _ConversationHistoryState();
}

class _ConversationHistoryState extends State<ConversationHistory> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> filteredConversations = [];
  bool isLoading = true;

  // Selected mood filters
  Set<String> selectedMoodFilters = {};

  // Map for converting database emotion names to display names
  final Map<String, String> emotionDisplayNames = {
    'Joy': 'Happy',
    'Trust': 'Confident',
    'Fear': 'Anxious',
    'Surprise': 'Shock',
    'Sadness': 'Sad',
    'Disgust': 'Disgust', // No change
    'Anger': 'Annoyance',
    'Anticipation': 'Curiosity',
  };

  // Reverse mapping for display name to database name
  late final Map<String, String> displayToDbEmotions;

  // Get display name for an emotion
  String getEmotionDisplayName(String dbName) {
    return emotionDisplayNames[dbName] ?? dbName;
  }

  @override
  void initState() {
    super.initState();
    // Initialize the reverse mapping
    displayToDbEmotions = Map.fromEntries(
        emotionDisplayNames.entries.map((e) => MapEntry(e.value, e.key)));
    fetchConversations();
  }

  // Apply the current mood filters to the conversations
  void applyFilters() {
    if (selectedMoodFilters.isEmpty) {
      // No filters, show all conversations
      filteredConversations = List.from(conversations);
    } else {
      // Apply filters
      filteredConversations = conversations.where((conversation) {
        final emotions = (conversation['emotions'] ?? []) as List<dynamic>;

        // Check if any of the emotions in this conversation match our selected filters
        for (var emotion in emotions) {
          final dbEmotion = emotion['basic_emotion'];
          if (dbEmotion != null) {
            final displayName = getEmotionDisplayName(dbEmotion);
            if (selectedMoodFilters.contains(displayName)) {
              return true; // Conversation has at least one of the selected emotions
            }
          }
        }
        return false; // No matching emotions found
      }).toList();
    }

    setState(() {});
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

      final fetchedConversations = snapshot.docs.map((doc) {
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
          'transcript':
              data['transcript'] ?? '', // Updated field name from transcription
          'emotions': extractedEmotions,
          'associations': associations,
          'emotional_analysis': data['emotional_analysis'] ?? '',
        };
      }).toList();

      setState(() {
        conversations = fetchedConversations;
        filteredConversations =
            fetchedConversations; // Initial unfiltered state
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
    return '${sentences[0]} ${sentences[1]}...';
  }

  Widget buildSoftCard({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
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
        // Add to uniqueEmotions using the database name
        uniqueEmotions.add(basicEmotion);

        // Create a new emotion object with display name
        final displayEmotion = <String, dynamic>{...emotion};
        displayEmotion['display_name'] = getEmotionDisplayName(basicEmotion);

        filteredEmotions.add(displayEmotion);
      }
    }

    return buildSoftCard(
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
      child: Padding(
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
                      final displayEmotion =
                          emotion['display_name']; // Use display name
                      return Chip(
                        label: Text(
                          displayEmotion, // Show display name instead of database name
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
    final String lowerEmotion = emotion.toLowerCase();

    switch (lowerEmotion) {
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
        return Colors.grey;
    }
  }

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

  // Show filter dialog with mood checkboxes
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create a StatefulBuilder to manage state within the dialog
        return StatefulBuilder(builder: (context, setDialogState) {
          // All available moods for filtering (using display names)
          final List<String> allMoods = [
            'Happy',
            'Confident',
            'Anxious',
            'Shock',
            'Sad',
            'Disgust',
            'Annoyance',
            'Curiosity'
          ];

          return AlertDialog(
            title: const Text('Filter by Mood'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select moods to filter by:'),
                  const SizedBox(height: 16),

                  // List of checkboxes for each mood
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: allMoods.map((mood) {
                        return CheckboxListTile(
                          title: Text(mood),
                          value: selectedMoodFilters.contains(mood),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedMoodFilters.add(mood);
                              } else {
                                selectedMoodFilters.remove(mood);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear all filters
                  setDialogState(() {
                    selectedMoodFilters.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply the filters and close the dialog
                  Navigator.pop(context, true);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    ).then((applyFilter) {
      if (applyFilter == true) {
        applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Conversation History'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Filter button with badge indicator when filters are active
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterDialog,
              ),

              // Show a badge when filters are active
              if (selectedMoodFilters.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: buildCalendar(),
              ),

              // Show filter info when filters are active
              if (selectedMoodFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Filtered by: ${selectedMoodFilters.join(", ")}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedMoodFilters.clear();
                                    applyFilters();
                                  });
                                },
                                child: const Icon(Icons.clear, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredConversations.isEmpty
                        ? const Center(
                            child: Text('No conversations found for this week.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                )),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredConversations.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: buildConversationCard(
                                  filteredConversations[index]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
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
