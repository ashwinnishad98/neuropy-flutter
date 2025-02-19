import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Future<void> addEmotion(String emotionLabel, int intensity) async {
    await FirebaseFirestore.instance.collection('emotions').add({
      'emotion': emotionLabel,
      'intensity': intensity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
