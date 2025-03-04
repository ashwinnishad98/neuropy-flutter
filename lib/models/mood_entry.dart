import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String transcript;
  final List<Map<String, dynamic>> emotions;
  final DateTime timestamp;

  MoodEntry({
    required this.transcript, 
    required this.emotions,
    required this.timestamp,
  });

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    // Handle transcript field
    String transcriptText = map['transcript'] ?? '';
    
    // Handle emotions field - the problematic part
    List<Map<String, dynamic>> emotionsList = [];
    
    if (map.containsKey('emotions')) {
      var emotionsData = map['emotions'];
      
      if (emotionsData is List) {
        // If emotions is already a list, use it directly
        emotionsList = List<Map<String, dynamic>>.from(
          emotionsData.map((e) => e is Map<String, dynamic> ? e : {})
        );
      } else if (emotionsData is Map) {
        // If emotions is a map, convert it to a list of maps
        emotionsData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            // Add basic_emotion field if not present
            if (!value.containsKey('basic_emotion')) {
              value['basic_emotion'] = key;
            }
            emotionsList.add(value);
          } else {
            // Simple key-value entry
            emotionsList.add({
              'basic_emotion': key,
              'value': value
            });
          }
        });
      }
    }
    
    // Handle timestamp field
    DateTime timestampDate;
    final timestampField = map['timestamp'];
    
    if (timestampField is Timestamp) {
      timestampDate = timestampField.toDate();
    } else if (timestampField is DateTime) {
      timestampDate = timestampField;
    } else {
      timestampDate = DateTime.now();
    }
    
    return MoodEntry(
      transcript: transcriptText,
      emotions: emotionsList,
      timestamp: timestampDate,
    );
  }
}