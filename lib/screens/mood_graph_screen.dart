import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../utils/emotion_colors.dart';

class MoodGraphScreen extends StatefulWidget {
  const MoodGraphScreen({Key? key}) : super(key: key);

  @override
  _MoodGraphScreenState createState() => _MoodGraphScreenState();
}

class _MoodGraphScreenState extends State<MoodGraphScreen> {
  DateTime selectedWeek = DateTime.now();
  bool isSelfLog = true;
  Map<String, List<String>> moodData = {}; // Holds mood data for the graph

  // Map between database emotion names and UI display names
  static final Map<String, String> dbToDisplayMap = {
    'Joy': 'Happy',
    'Anger': 'Annoyance',
    'Sadness': 'Sad',
    'Fear': 'Anxious',
    'Trust': 'Confident',
    'Disgust': 'Disgust',
    'Surprise': 'Shock',
    'Anticipation': 'Curiosity',
  };

  @override
  void initState() {
    super.initState();
    fetchMoodData();
  }

  Future<void> fetchMoodData() async {
    final startOfWeek =
        selectedWeek.subtract(Duration(days: selectedWeek.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('emotions')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy('timestamp')
          .get();

      final Map<String, List<String>> fetchedData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final day = DateFormat('EEE').format(timestamp); // e.g., "Mon", "Tue"
        
        // Ensure we're getting the database name from Firestore
        final dbEmotion = data['emotion'] as String;
        
        if (!fetchedData.containsKey(day)) {
          fetchedData[day] = [];
        }
        
        // Store the database name in our local data structure
        fetchedData[day]!.add(dbEmotion);
      }

      setState(() {
        moodData = fetchedData;
      });
    } catch (e) {
      print('Error fetching mood data: $e');
    }
  }

  void changeWeek(int offset) {
    setState(() {
      selectedWeek = selectedWeek.add(Duration(days: offset * 7));
    });
    fetchMoodData();
  }

  Widget buildWeekNavigation() {
    final startOfWeek =
        selectedWeek.subtract(Duration(days: selectedWeek.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => changeWeek(-1),
        ),
        Text(
          '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: selectedWeek.isBefore(DateTime.now())
              ? () => changeWeek(1)
              : null,
        ),
      ],
    );
  }

  Widget buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Self Log'),
        Switch(
          value: isSelfLog,
          onChanged: (value) {
            setState(() {
              isSelfLog = value;
            });
            fetchMoodData(); // Fetch new data based on the toggle state
          },
        ),
      ],
    );
  }

  Widget buildLegend() {
    // Define legend items with display names, but use db names for color lookup
    final List<Map<String, String>> legendItems = [
      {'display': 'Happy', 'db': 'Joy'},
      {'display': 'Confident', 'db': 'Trust'},
      {'display': 'Anxious', 'db': 'Fear'},
      {'display': 'Shock', 'db': 'Surprise'},
      {'display': 'Sad', 'db': 'Sadness'},
      {'display': 'Disgust', 'db': 'Disgust'},
      {'display': 'Annoyance', 'db': 'Anger'},
      {'display': 'Curiosity', 'db': 'Anticipation'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: legendItems.map((item) {
        final color = MoodGraphPainter.getEmotionColorStatic(item['db']!);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item['display']!,
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget buildMoodGraph() {
    final startOfWeek =
        selectedWeek.subtract(Duration(days: selectedWeek.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    bool hasData = moodData.isNotEmpty;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(40.0, 16.0, 16.0, 40.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: !hasData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mood,
                      size: 48, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No mood data for this week',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : CustomPaint(
              painter: MoodGraphPainter(moodData, startOfWeek, endOfWeek),
              size: const Size(double.infinity, double.infinity),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mood Record'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: TabBarView(
          children: [
            Column(
              children: [
                buildWeekNavigation(),
                const SizedBox(height: 8),
                buildToggleButton(),
                const SizedBox(height: 8),
                buildLegend(),
                const SizedBox(height: 8),
                Expanded(child: buildMoodGraph()),
              ],
            ),
            Center(child: Text('Monthly View Coming Soon')),
            Center(child: Text('Yearly View Coming Soon')),
          ],
        ),
      ),
    );
  }
}

class MoodGraphPainter extends CustomPainter {
  final Map<String, List<String>> moodData;
  final DateTime startOfWeek;
  final DateTime endOfWeek;

  MoodGraphPainter(this.moodData, this.startOfWeek, this.endOfWeek);

  // Map between database emotion names and UI display names
  static final Map<String, String> dbToDisplayMap = {
    'Joy': 'Happy',
    'Anger': 'Annoyance',
    'Sadness': 'Sad',
    'Fear': 'Anxious',
    'Trust': 'Confident',
    'Disgust': 'Disgust',
    'Surprise': 'Shock',
    'Anticipation': 'Curiosity',
  };

  // Map between UI display names and Y positions
  static final Map<String, int> displayNameToPosition = {
    'Happy': 1,
    'Confident': 2,
    'Curiosity': 3,
    'Shock': 4,
    'Anxious': 5,
    'Annoyance': 6,
    'Disgust': 7,
    'Sad': 8,
  };

  @override
  void paint(Canvas canvas, Size size) {
    // Define margin space for labels
    const double leftMargin = 30.0;
    const double bottomMargin = 30.0;

    // Adjust canvas size to account for margins
    final graphSize = Size(size.width - leftMargin, size.height - bottomMargin);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Set up y-position mapping using display names
    final Map<String, double> yPositions = {};
    
    // First, map the display names to their y-positions
    displayNameToPosition.forEach((displayName, position) {
      yPositions[displayName] = graphSize.height * (position / 8);
    });
    
    // Then, map the database names to the same y-positions as their display name counterparts
    // This ensures we can use moodData (which has DB names) to determine y-positions
    dbToDisplayMap.forEach((dbName, displayName) {
      yPositions[dbName] = yPositions[displayName]!;
    });

    final dayWidth = graphSize.width / daysOfWeek.length;
    final gradientPaths = <Path>[];

    // Transform canvas to account for margins
    canvas.translate(leftMargin, 0);

    // Draw grid and labels with display names
    _drawGridAndLabels(
        canvas, graphSize, daysOfWeek, yPositions, dayWidth, paint);

    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      if (!moodData.containsKey(day)) continue;

      // Calculate x position at day center (between grid lines)
      final xPosition = dayWidth * (i + 0.5); // Center of the column

      // Draw dots for each emotion of the day
      for (var dbEmotion in moodData[day]!) {
        paint.color = getEmotionColor(dbEmotion); // Get color using DB name

        // Get y-position directly using the DB emotion name
        final yPosition = yPositions[dbEmotion];

        // Draw a circle for emotions
        if (yPosition != null) {
          canvas.drawCircle(Offset(xPosition, yPosition), 6, paint);
        }
      }

      // Create gradient paths for multiple emotions on the same day
      if (moodData[day]!.length > 1) {
        final path = Path();
        final emotionsForDay = moodData[day]!;

        for (int j = 0; j < emotionsForDay.length; j++) {
          final dbEmotion = emotionsForDay[j];
          final yPosition = yPositions[dbEmotion]; // Get position using DB name

          if (yPosition != null) {
            if (j == 0) {
              path.moveTo(xPosition, yPosition);
            } else {
              path.lineTo(xPosition, yPosition);
            }
          }
        }

        path.close();
        gradientPaths.add(path);
      }
    }

    // Reset translation before drawing paths
    canvas.translate(-leftMargin, 0);

    // Draw gradients between dots
    for (var path in gradientPaths) {
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.red.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(path.getBounds())
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, gradientPaint);
    }
  }

  void _drawGridAndLabels(Canvas canvas, Size size, List<String> daysOfWeek,
      Map<String, double> yPositions, double dayWidth, Paint paint) {
    // Set up paint for grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Set up paint for axis lines
    final axisPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Set up paint for day center dotted lines
    final dayCenterPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5) // Darker than grid
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // We need to draw grid lines only for display names, not db names
    final displayNameYPositions = displayNameToPosition.map((key, value) => 
      MapEntry(key, size.height * (value / 8))
    );

    // Draw horizontal grid lines for each emotion level
    displayNameYPositions.forEach((emotionName, yPosition) {
      canvas.drawLine(
        Offset(0, yPosition),
        Offset(size.width, yPosition),
        gridPaint,
      );
    });

    // ...existing code for drawing days and other elements...

    final dayTextStyle = TextStyle(
      fontSize: 10,
      color: Colors.black87,
      fontWeight: FontWeight.w600,
    );

    final dateTextStyle = TextStyle(
      fontSize: 9,
      color: Colors.black54,
      fontWeight: FontWeight.normal,
    );

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );

    // Draw emotion labels on  the y-axis using the display names only
    displayNameYPositions.forEach((emotionName, yPosition) {
      textPainter.text = TextSpan(
        text: emotionName,
        style: TextStyle(
          fontSize: 10,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas,
          Offset(-textPainter.width - 5, yPosition - textPainter.height / 2));
    });

    // ...existing code for drawing days and dates...
    
    for (int i = 0; i < daysOfWeek.length; i++) {
      final xPosition = dayWidth * (i + 0.5); // Center of day column

      // Draw dotted line for day centers
      for (double y = 2; y < size.height; y += 8) {
        canvas.drawLine(
          Offset(xPosition, y),
          Offset(xPosition, y + 4),
          dayCenterPaint,
        );
      }
    }

    // Draw all border lines
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), axisPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    // Draw day labels
    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      final xPosition = dayWidth * (i + 0.5);
      final date = startOfWeek.add(Duration(days: i));

      textPainter.text = TextSpan(
        children: [
          TextSpan(text: day, style: dayTextStyle),
          TextSpan(text: '\n${DateFormat('MMM d').format(date)}', style: dateTextStyle),
        ],
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(xPosition - textPainter.width / 2, size.height + 5));
    }

    // Highlight today if it's in the displayed week
    final today = DateTime.now();
    if (today.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
        today.isBefore(endOfWeek.add(Duration(days: 1)))) {
      final dayIndex = today.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < daysOfWeek.length) {
        final xPosition = dayWidth * (dayIndex + 0.5);
        
        final highlightPaint = Paint()
          ..color = const Color.fromARGB(255, 94, 219, 250).withOpacity(0.15)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            xPosition - dayWidth / 2 + 1,
            0,
            dayWidth - 2,
            size.height,
          ),
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color getEmotionColor(String dbEmotion) {
    // Use the DB emotion name directly for color lookup
    return EmotionColors.getColor(dbEmotion);
  }

  static Color getEmotionColorStatic(String dbEmotion) {
    // Use the DB emotion name directly for color lookup
    return EmotionColors.getColor(dbEmotion);
  }
}
