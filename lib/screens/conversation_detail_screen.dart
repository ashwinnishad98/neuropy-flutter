import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> conversation;

  const ConversationDetailScreen({Key? key, required this.conversation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = conversation['timestamp'] as DateTime;
    final transcription = conversation['transcription'] as String;
    final emotions = (conversation['emotions'] ?? []) as List<dynamic>;
    final events = (conversation['events'] ?? []) as List<dynamic>;
    final people = (conversation['people'] ?? []) as List<dynamic>;
    final locations = (conversation['locations'] ?? []) as List<dynamic>;

    // Calculate mood proportions dynamically
    final moodProportions = calculateMoodProportions(emotions);

    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 224, 224, 224), // Updated background color
      appBar: AppBar(
        title: const Text('Conversation Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            buildDateSection(timestamp),

            const SizedBox(height: 16),

            // Neuropy Summary Section
            buildNeuropySummary(),

            const SizedBox(height: 16),

            // Mood Proportion Section
            buildMoodProportionSection(moodProportions),

            const SizedBox(height: 16),

            // Transcription Section
            buildRoundedSection(
              title: 'Transcription',
              content: transcription,
            ),

            const SizedBox(height: 16),

            // Location Section
            if (locations.isNotEmpty)
              buildRoundedSection(
                title: 'Location',
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
                title: 'Event',
                content: events.join('\n'),
              ),
          ],
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
      ),
      child: Center(
        child: Text(
          DateFormat('EEEE, MMMM dd, yyyy')
              .format(timestamp), // Format the date
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget buildNeuropySummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            255, 72, 191, 169), // Light teal color for the summary bubble
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Neuropy Summary',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.auto_awesome, size: 18), // Sparkle icon
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Today, you seemed joyful during the afternoon after discussing your hike! '
            'Consider more outdoor activities to reduce anxiety, as seen from last week\'s improvement.',
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> calculateMoodProportions(List<dynamic> emotions) {
    if (emotions.isEmpty) return [];

    // Extract unique emotions by splitting at " (" and removing intensity
    final uniqueEmotions = emotions.map((e) => e.split(' (')[0]).toSet();

    // Calculate percentage for each emotion
    final percentage = (100 / uniqueEmotions.length).round();

    return uniqueEmotions.map((emotion) {
      return {
        'label': emotion,
        'value': percentage,
        'color': getEmotionColor(emotion),
      };
    }).toList();
  }

  Widget buildMoodProportionSection(
      List<Map<String, dynamic>> moodProportions) {
    if (moodProportions.isEmpty) {
      return const SizedBox(); // Return an empty widget if there are no emotions
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
            content,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
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
}
