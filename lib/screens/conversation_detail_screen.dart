import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/emotion_colors.dart';

class ConversationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> conversation;

  const ConversationDetailScreen({Key? key, required this.conversation})
      : super(key: key);

  // Map for converting database emotion names to display names
  static const Map<String, String> emotionDisplayNames = {
    'Joy': 'Happy',
    'Trust': 'Confident',
    'Fear': 'Anxious',
    'Surprise': 'Shock',
    'Sadness': 'Sad',
    'Disgust': 'Disgust', // No change
    'Anger': 'Annoyance',
    'Anticipation': 'Curiosity',
  };

  // Get display name for an emotion
  static String getEmotionDisplayName(String dbName) {
    return emotionDisplayNames[dbName] ?? dbName;
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from the conversation structure
    final timestamp = (conversation['timestamp'] as Timestamp).toDate();
    final transcript = conversation['transcript'] as String;
    final emotions = (conversation['emotions'] ?? []) as List<dynamic>;
    final associations = conversation['associations'] as Map<String, dynamic>?;
    final emotionalAnalysis = conversation['emotional_analysis'] as String;

    // Extract location data (Environment in new schema)
    List<String> locations = [];
    if (associations != null && associations.containsKey('Environment')) {
      final environmentMap =
          associations['Environment'] as Map<String, dynamic>?;
      if (environmentMap != null) {
        environmentMap.forEach((emotion, locationList) {
          if (locationList is List) {
            for (var location in locationList) {
              if (location is String && location.isNotEmpty) {
                locations.add('$location ($emotion)');
              }
            }
          }
        });
      }
    }

    // Extract people data
    List<String> people = [];
    if (associations != null && associations.containsKey('People')) {
      final peopleMap = associations['People'] as Map<String, dynamic>?;
      if (peopleMap != null) {
        peopleMap.forEach((emotion, personList) {
          if (personList is List) {
            for (var person in personList) {
              if (person is String && person.isNotEmpty) {
                people.add('$person ($emotion)');
              }
            }
          }
        });
      }
    }

    // Extract events data
    List<String> events = [];
    if (associations != null && associations.containsKey('Events')) {
      final eventsMap = associations['Events'] as Map<String, dynamic>?;
      if (eventsMap != null) {
        eventsMap.forEach((emotion, eventList) {
          if (eventList is List) {
            for (var event in eventList) {
              if (event is String && event.isNotEmpty) {
                events.add('$event ($emotion)');
              }
            }
          }
        });
      }
    }

    // Extract objects data
    List<String> objects = [];
    if (associations != null && associations.containsKey('Objects')) {
      final objectsMap = associations['Objects'] as Map<String, dynamic>?;
      if (objectsMap != null) {
        objectsMap.forEach((emotion, objectList) {
          if (objectList is List) {
            for (var object in objectList) {
              if (object is String && object.isNotEmpty) {
                objects.add('$object ($emotion)');
              }
            }
          }
        });
      }
    }

    // Calculate mood proportions dynamically with mapping to display names
    final moodProportions = calculateMoodProportions(emotions);

    return Scaffold(
      // Remove extendBodyBehindAppBar to fix black bar issue
      backgroundColor: const Color.fromARGB(255, 197, 185, 245),
      appBar: AppBar(
        title: const Text('Conversation Details'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 131, 229, 211),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // Use BoxDecoration for the gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 131, 229, 211), // Light teal
              Color.fromARGB(255, 208, 230, 247), // Light blue
              Color.fromARGB(255, 197, 185, 245), // Light purple
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Section
              buildDateSection(timestamp),

              const SizedBox(height: 16),

              // Neuropy Summary Section
              buildNeuropySummary(emotionalAnalysis),

              const SizedBox(height: 16),

              // Mood Proportion Section
              buildMoodProportionSection(moodProportions),

              const SizedBox(height: 16),

              // Transcript Section
              buildRoundedSection(
                title: 'Transcript',
                content: transcript,
              ),

              const SizedBox(height: 16),

              // Location Section
              if (locations.isNotEmpty)
                buildRoundedSection(
                  title: 'Environment',
                  content: locations.join('\n'),
                ),

              const SizedBox(height: 16),

              // People Section
              if (people.isNotEmpty)
                buildRoundedSection(
                  title: 'People',
                  content: people.join('\n'),
                ),

              const SizedBox(height: 16),

              // Events Section
              if (events.isNotEmpty)
                buildRoundedSection(
                  title: 'Events',
                  content: events.join('\n'),
                ),

              const SizedBox(height: 16),

              // Objects Section
              if (objects.isNotEmpty)
                buildRoundedSection(
                  title: 'Objects',
                  content: objects.join('\n'),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateSection(DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
      child: Center(
        child: Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(timestamp),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget buildNeuropySummary(String summary) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 72, 191, 169),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Neuropy Summary',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 4),
              Icon(Icons.auto_awesome, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> calculateMoodProportions(List<dynamic> emotions) {
    if (emotions.isEmpty) return [];

    // Count occurrences of each basic emotion
    Map<String, int> emotionCounts = {};
    for (var emotion in emotions) {
      String basicEmotion = emotion['basic_emotion'] as String;
      if (basicEmotion != 'Unknown') {
        emotionCounts[basicEmotion] = (emotionCounts[basicEmotion] ?? 0) + 1;
      }
    }

    // Calculate total for percentage
    final totalEmotions =
        emotionCounts.values.fold(0, (sum, count) => sum + count);
    if (totalEmotions == 0) return [];

    // Convert to list of maps with percentage values and map to display names
    return emotionCounts.entries.map((entry) {
      final percentage = ((entry.value / totalEmotions) * 100).round();

      // Use display name instead of database name
      final displayLabel = getEmotionDisplayName(entry.key);

      return {
        'label': displayLabel, // Use display name for UI
        'value': percentage,
        'color': getEmotionColor(entry.key),
        'originalEmotion': entry.key
      };
    }).toList();
  }

  Widget buildMoodProportionSection(
      List<Map<String, dynamic>> moodProportions) {
    if (moodProportions.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Proportion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: moodProportions.map((mood) {
                    return Expanded(
                      flex: mood['value'] as int,
                      child: Container(
                        height: 12,
                        color: mood['color'] as Color,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: moodProportions.map((mood) {
              return Text(
                '${mood['label']} ${mood['value']}%',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildRoundedSection({required String title, required String content}) {
    String processedContent = content;

    // Replace all emotion names in parentheses with their display names
    emotionDisplayNames.forEach((dbName, displayName) {
      processedContent =
          processedContent.replaceAll('($dbName)', '($displayName)');
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            processedContent,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Color getEmotionColor(String emotion) {
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
        return Colors.grey;
    }
  }
}
