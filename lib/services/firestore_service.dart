import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Map UI display names to the database emotion names
  static final Map<String, String> displayToDbEmotions = {
    'Happy': 'Joy',
    'Confident': 'Trust',
    'Anxious': 'Fear',
    'Shock': 'Surprise',
    'Sad': 'Sadness',
    'Disgust': 'Disgust', // No change
    'Annoyance': 'Anger',
    'Curiosity': 'Anticipation',
  };

  static Future<void> addEmotion(String emotionDisplayName, int intensity) async {
    try {
      // Convert display name to database name for storage
      final String dbEmotionName = displayToDbEmotions[emotionDisplayName] ?? emotionDisplayName;
      
      await FirebaseFirestore.instance.collection('emotions').add({
        'emotion': dbEmotionName, // Store DB name, not display name
        'intensity': intensity,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error adding emotion: $e');
      rethrow;
    }
  }
}
