import 'package:flutter/material.dart';

class Emotion {
  final String label; // Name of the emotion
  final Color color; // Color associated with the emotion
  final String imagePath; // Path to the image asset

  const Emotion({
    required this.label,
    required this.color,
    required this.imagePath,
  });

  // Optional: Factory method to create an Emotion from a Map (e.g., Firestore data)
  factory Emotion.fromMap(Map<String, dynamic> map) {
    return Emotion(
      label: map['label'] as String,
      color: Color(map['color'] as int),
      imagePath: map['image'] as String,
    );
  }

  // Optional: Convert an Emotion to a Map (e.g., for Firestore storage)
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'color': color.value,
      'image': imagePath,
    };
  }
}
