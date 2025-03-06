import 'package:flutter/material.dart';

class EmotionColors {
  const EmotionColors._();

  // Base emotion colors
  static const Color joy = Color.fromARGB(255, 246, 173, 53);
  static const Color trust = Color.fromARGB(255, 166, 194, 50);
  static const Color fear = Color.fromARGB(255, 56, 155, 78);
  static const Color surprise = Color.fromARGB(255, 39, 187, 159);
  static const Color sadness = Color.fromARGB(255, 61, 157, 255);
  static const Color disgust = Color.fromARGB(255, 120, 87, 255);
  static const Color anger = Color.fromARGB(255, 255, 92, 101);
  static const Color anticipation = Color.fromARGB(255, 252, 117, 87);

  // Default color for unknown emotions
  static const Color unknown = Color.fromARGB(255, 170, 170, 170);

  // Gray color used for unselected emotions
  static const Color unselectedGray = Color.fromARGB(255, 210, 210, 210);

  /// Get color for an emotion by name
  static Color getColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return joy;
      case 'trust':
        return trust;
      case 'fear':
        return fear;
      case 'surprise':
        return surprise;
      case 'sadness':
        return sadness;
      case 'disgust':
        return disgust;
      case 'anger':
        return anger;
      case 'anticipation':
        return anticipation;
      default:
        return unknown;
    }
  }

  /// Map of all emotions and their colors
  static final Map<String, Color> emotionColorMap = {
    'Joy': joy,
    'Trust': trust,
    'Fear': fear,
    'Surprise': surprise,
    'Sadness': sadness,
    'Disgust': disgust,
    'Anger': anger,
    'Anticipation': anticipation,
  };
}
