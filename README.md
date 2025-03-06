# Neuropy App

A Flutter mobile application for mood tracking and emotional analysis. Capstone project in collaboration between the University of Washington and T-Mobile.

<p align="center">
  <img src="screenshots/home_screen.png" alt="Home Screen" width="250"/>
</p>

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Features](#features)
- [Screenshots](#screenshots)
- [Setup and Installation](#setup-and-installation)
- [Running the App](#running-the-app)
- [Dependencies](#dependencies)

## Overview

Neuropy is a mobile application designed to help users track their emotions, identify patterns in their mood, and understand emotional connections to various life factors. The app uses a combination of self-reported emotions and AI-analyzed conversations to create a comprehensive emotional profile.

Key capabilities:
- Track daily moods using an emotion wheel interface
- Visualize emotional patterns on time-based graphs
- Analyze connections between emotions and life factors
- Review conversation transcripts with emotion analysis
- Filter emotional data by mood types

## Project Structure

```
neuropy_app/
│
├── lib/                  # Main application code
│   ├── models/           # Data models for the app
│   ├── screens/          # UI screens and pages
│   ├── services/         # Backend services (Firestore integration)
│   ├── utils/            # Utility functions and constants
│   ├── widgets/          # Reusable UI components
│   └── main.dart         # App entry point
│
├── assets/               # Images, icons, and other static resources
│
├── screenshots/          # App screenshots for documentation
│
├── ios/                  # iOS-specific configuration
│
├── android/              # Android-specific configuration
│
├── pubspec.yaml          # Flutter dependencies and configuration
```

### Key Directories

- **models/**: Contains data structures like `Emotion` and `MoodEntry` that define how information is stored and manipulated in the app.

- **screens/**: Contains the main UI screens of the application:
  - `home_screen.dart`: The main landing page with summary views
  - `emotion_wheel_screen.dart`: The emotion selection wheel interface
  - `mood_graph_screen.dart`: Time-based visualization of emotions
  - `mood_cloud_screen.dart`: Visualization of mood statistics
  - `conversation_history.dart`: List of analyzed conversations
  - `conversation_detail_screen.dart`: Detailed view of a conversation with emotional analysis

- **services/**: Contains code for interacting with external services:
  - `firestore_service.dart`: Manages communication with Firebase Firestore database

- **utils/**: Utility classes and helper functions:
  - `emotion_colors.dart`: Color definitions for each emotion type

- **widgets/**: Reusable components:
  - `emotion_wheel_painter.dart`: Custom painter for the emotion wheel UI

## Features

### Emotion Logging
Track your daily emotions using an intuitive wheel interface with varying intensity levels.

<p align="center">
  <img src="screenshots/emotion_wheel.png" alt="Emotion Wheel" width="250"/>
</p>

### Mood Analysis
View visual representations of your emotional patterns over time with interactive graphs.

<p align="center">
  <img src="screenshots/mood_graph.png" alt="Mood Graph" width="250"/>
</p>

### Conversation Journal
Read through past conversations with AI-powered emotional analysis.

<p align="center">
  <img src="screenshots/conversation_history.png" alt="Conversation History" width="250"/>
</p>

### Factor Analysis
Explore how different life factors correlate with your emotions through interactive bubble charts.

<p align="center">
  <img src="screenshots/mood_cloud.png" alt="Mood Cloud" width="250"/>
</p>

### Conversation Details
See comprehensive analysis of each conversation with emotion proportions and key elements.

<p align="center">
  <img src="screenshots/conversation_detail.png" alt="Conversation Detail" width="250"/>
</p>

## Screenshots

<p align="center">
  <img src="screenshots/home_screen.png" alt="Home Screen" width="200"/>
  <img src="screenshots/emotion_wheel.png" alt="Emotion Wheel" width="200"/>
  <img src="screenshots/mood_graph.png" alt="Mood Graph" width="200"/>
  <img src="screenshots/conversation_history.png" alt="Conversation History" width="200"/>
</p>
<p align="center">
  <img src="screenshots/mood_cloud.png" alt="Mood Cloud" width="200"/>
  <img src="screenshots/conversation_detail.png" alt="Conversation Detail" width="200"/>
  <img src="screenshots/mood_detail.png" alt="Mood Detail" width="200"/>
  <img src="screenshots/factor_detail.png" alt="Factor Detail" width="200"/>
</p>

## Setup and Installation

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- For iOS development:
  - Mac with macOS
  - Xcode (latest version)
  - iOS Simulator or physical iOS device
- For Android development:
  - Android Studio
  - Android SDK
  - Android Emulator or physical Android device
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repository/neuropy-app.git
   cd neuropy-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Follow the [Firebase Flutter setup guide](https://firebase.google.com/docs/flutter/setup) to add your own Firebase project
   - Place the required configuration files (`GoogleService-Info.plist` for iOS and `google-services.json` for Android) in their respective directories

## Running the App

### Using Visual Studio Code

1. Open the project in VS Code
2. Ensure you have the Flutter extension installed
3. Select a device from the status bar at the bottom
4. Press F5 or click "Run > Start Debugging"

### Using Command Line

Run the app in debug mode:
```bash
flutter run
```

### Running on macOS with iPhone Simulator

1. Open Xcode and launch an iOS Simulator
2. In terminal, navigate to your project directory and run:
   ```bash
   open -a Simulator
   flutter run
   ```

### Running on Windows for iOS Development

iOS development is only supported on macOS, as it requires Xcode.

### Running on a Physical iOS Device

1. Connect your iOS device to your Mac
2. Open the project in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```
3. In Xcode:
   - Select your device from the device dropdown
   - Set up your development team in "Signing & Capabilities"
   - Build and run the app

4. Alternatively, if your iOS device has Developer Mode enabled:
   ```bash
   flutter run -d your-device-id
   ```
   (Find your device ID with `flutter devices`)

## Dependencies

Major packages used in this project:

- `firebase_core` & `cloud_firestore`: Firebase integration
- `bubble_chart`: For bubble chart visualizations
- `intl`: For date formatting and internationalization
- `provider`: For state management

For a complete list of dependencies, see the `pubspec.yaml` file.