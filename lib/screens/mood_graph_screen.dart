import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class MoodGraphScreen extends StatefulWidget {
  const MoodGraphScreen({Key? key}) : super(key: key);

  @override
  _MoodGraphScreenState createState() => _MoodGraphScreenState();
}

class _MoodGraphScreenState extends State<MoodGraphScreen> {
  DateTime selectedWeek = DateTime.now();
  bool isSelfLog =
      true; // Toggle state: true for Self-Log, false for Mood Estimate
  Map<String, List<String>> moodData = {}; // Holds mood data for the graph

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
        final emotion = data['emotion'] as String;

        if (!fetchedData.containsKey(day)) {
          fetchedData[day] = [];
        }
        fetchedData[day]!.add(emotion);
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
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: [
        'Joy', 'Trust', 'Fear', 'Surprise', 'Sadness', 'Disgust', 'Anger', 'Anticipation'
      ].map((emotion) {
        final color = MoodGraphPainter.getEmotionColorStatic(emotion);
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
              emotion,
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
      padding: const EdgeInsets.fromLTRB(40.0, 16.0, 16.0, 40.0), // Increased bottom padding
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
                  Icon(Icons.mood, size: 48, color: Colors.grey.withOpacity(0.5)),
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
          title: const Text('Mood Graph'),
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
        backgroundColor: const Color.fromARGB(255, 224, 224, 224),
        body: TabBarView(
          children: [
            Column(
              children: [
                buildWeekNavigation(),
                const SizedBox(height: 8),
                buildToggleButton(),
                const SizedBox(height: 8),
                buildLegend(), // Add the legend here
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

  @override
  void paint(Canvas canvas, Size size) {
    // Define margin space for labels
    const double leftMargin = 30.0;
    const double bottomMargin = 30.0;
    
    // Adjust canvas size to account for margins
    final graphSize = Size(
      size.width - leftMargin, 
      size.height - bottomMargin
    );
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final yPositions = <String, double>{
      'Joy': graphSize.height * (1 / 8),
      'Trust': graphSize.height * (2 / 8),
      'Anticipation': graphSize.height * (3 / 8),
      'Surprise': graphSize.height * (4 / 8),
      'Fear': graphSize.height * (5 / 8),
      'Anger': graphSize.height * (6 / 8),
      'Disgust': graphSize.height * (7 / 8),
      'Sadness': graphSize.height * (8 / 8),
    };

    final dayWidth = graphSize.width / daysOfWeek.length;
    final gradientPaths = <Path>[];

    // Transform canvas to account for margins
    canvas.translate(leftMargin, 0);
    
    // Draw grid and labels
    _drawGridAndLabels(canvas, graphSize, daysOfWeek, yPositions, dayWidth, paint);

    // Now draw the data points - for each day, draw at the DAY CENTER (not between lines)
    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      if (!moodData.containsKey(day)) continue;

      // Calculate x position at day center (between grid lines)
      final xPosition = dayWidth * (i + 0.5); // Center of the column

      // Draw dots for each emotion of the day
      for (var emotion in moodData[day]!) {
        paint.color = getEmotionColor(emotion);
        final yPosition = yPositions[emotion] ?? graphSize.height;

        // Draw a circle for emotions
        canvas.drawCircle(Offset(xPosition, yPosition), 6, paint);
      }

      // Create gradient paths for multiple emotions on the same day
      if (moodData[day]!.length > 1) {
        final path = Path();
        final emotionsForDay = moodData[day]!;

        for (int j = 0; j < emotionsForDay.length; j++) {
          final emotion = emotionsForDay[j];
          final yPosition = yPositions[emotion] ?? graphSize.height;

          if (j == 0) {
            path.moveTo(xPosition, yPosition);
          } else {
            path.lineTo(xPosition, yPosition);
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
      ..color = Colors.grey.withOpacity(0.5)  // Darker than grid
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines for each emotion level
    for (var entry in yPositions.entries) {
      final yPosition = entry.value;
      canvas.drawLine(
        Offset(0, yPosition),
        Offset(size.width, yPosition),
        gridPaint,
      );
    }

    // REMOVE THIS BLOCK - We're removing the solid vertical lines
    // for (int i = 0; i <= daysOfWeek.length; i++) {
    //   final xPosition = dayWidth * i;
    //   canvas.drawLine(
    //     Offset(xPosition, 0),
    //     Offset(xPosition, size.height),
    //     gridPaint,
    //   );
    // }
    
    // Draw vertical dotted lines at day centers (where data points are)
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
    
    // Draw left & right borders of the graph area
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      axisPaint,
    );
    
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      axisPaint,
    );
    
    // Draw top & bottom borders of the graph area
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      axisPaint,
    );
    
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    // Create multiple text styles for different label types - Keep these as is
    final emotionTextStyle = TextStyle(
      fontSize: 10,
      color: Colors.black87,
      fontWeight: FontWeight.w600, // Semibold
      letterSpacing: 0.2, // Slight letter spacing for readability
    );

    final dayTextStyle = TextStyle(
      fontSize: 10,
      color: Colors.black87,
      fontWeight: FontWeight.w600,
    );

    final dateTextStyle = TextStyle(
      fontSize: 9,
      color: Colors.black54, // Slightly lighter than the day
      fontWeight: FontWeight.normal,
    );

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );
    
    // Draw emotion labels as before
    for (var entry in yPositions.entries) {
      final emotion = entry.key;
      final yPosition = entry.value;
      
      textPainter.text = TextSpan(
        text: emotion,
        style: emotionTextStyle,
      );
      
      textPainter.layout();
      
      textPainter.paint(
        canvas, 
        Offset(-textPainter.width - 5, yPosition - textPainter.height / 2)
      );
    }
    
    // Draw day labels with dates at the CENTER of each day column
    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      final xPosition = dayWidth * (i + 0.5);
      
      // Calculate the date for this day
      final date = startOfWeek.add(Duration(days: i));
      
      // Always show both day and date, but formatted cleanly
      textPainter.text = TextSpan(
        children: [
          TextSpan(
            text: day,
            style: dayTextStyle,
          ),
          TextSpan(
            text: '\n${DateFormat('MMM d').format(date)}',
            style: dateTextStyle,
          ),
        ],
      );
      
      textPainter.layout();
      
      textPainter.paint(
        canvas, 
        Offset(xPosition - textPainter.width / 2, size.height + 5)
      );
    }

    // Highlight the current day if it's in this week - Keep this code
    final today = DateTime.now();
    if (today.isAfter(startOfWeek.subtract(Duration(days: 1))) && 
        today.isBefore(endOfWeek.add(Duration(days: 1)))) {
      
      // Calculate which day of the week is today (0-6)
      final dayIndex = today.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < daysOfWeek.length) {
        final xPosition = dayWidth * (dayIndex + 0.5); // Center of today's column
        
        // Draw a subtle highlight behind today's column
        final highlightPaint = Paint()
          ..color = const Color.fromARGB(255, 94, 219, 250).withOpacity(0.15)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(
          Rect.fromLTWH(
            xPosition - dayWidth / 2 + 1, // Left edge of column (with 1px gap)
            0,
            dayWidth - 2, // Width of column (with 1px gap on both sides)
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

  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return const Color.fromARGB(255, 247, 197, 34);
      case 'trust':
        return const Color.fromARGB(255, 155, 61, 130);
      case 'fear':
        return const Color.fromARGB(255, 124, 227, 255);
      case 'surprise':
        return const Color.fromARGB(255, 115, 233, 210);
      case 'sadness':
        return const Color.fromARGB(255, 62, 112, 252);
      case 'disgust':
        return const Color.fromARGB(255, 202, 130, 253);
      case 'anger':
        return const Color.fromARGB(255, 255, 126, 63);
      case 'anticipation':
        return const Color.fromARGB(255, 255, 125, 156);
      default:
        return Colors.grey;
    }
  }

  static Color getEmotionColorStatic(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return const Color.fromARGB(255, 247, 197, 34);
      case 'trust':
        return const Color.fromARGB(255, 155, 61, 130);
      case 'fear':
        return const Color.fromARGB(255, 124, 227, 255);
      case 'surprise':
        return const Color.fromARGB(255, 115, 233, 210);
      case 'sadness':
        return const Color.fromARGB(255, 62, 112, 252);
      case 'disgust':
        return const Color.fromARGB(255, 202, 130, 253);
      case 'anger':
        return const Color.fromARGB(255, 255, 126, 63);
      case 'anticipation':
        return const Color.fromARGB(255, 255, 125, 156);
      default:
        return Colors.grey;
    }
  }
}
