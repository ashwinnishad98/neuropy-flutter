import 'package:flutter/material.dart';
import 'mood_cloud_screen.dart';

class FactorScreen extends StatefulWidget {
  const FactorScreen({super.key});

  @override
  _FactorScreenState createState() => _FactorScreenState();
}

class _FactorScreenState extends State<FactorScreen> {
  int selectedToggleIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 131, 229, 211),
              Color.fromARGB(255, 208, 230, 247),
              Color.fromARGB(255, 197, 185, 245),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Factors',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Toggle Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedToggleIndex = 0;
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoodCloudScreen(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedToggleIndex == 0
                              ? Colors.black
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(20)),
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        child: Text(
                          "Mood",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedToggleIndex == 0
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedToggleIndex = 1;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedToggleIndex == 1
                              ? Colors.black
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(20)),
                          border: Border.all(color: Colors.black),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        child: Text(
                          "Factor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedToggleIndex == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Factor List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildFactorTile(Icons.work, 'Event'),
                    _buildFactorTile(Icons.people, 'People'),
                    _buildFactorTile(Icons.health_and_safety, 'Health'),
                    _buildFactorTile(Icons.nature, 'Environment'),
                    _buildFactorTile(Icons.category, 'Object'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactorTile(IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2.0,
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: () {},
      ),
    );
  }
}
