// File: lib/sctivity_screenn.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'Today';

  final List<Map<String, dynamic>> activityData = const [
    {'icon': Icons.camera_alt, 'title': 'Instagram Usage: 30 minutes', 'time': 'Today at 1:45 PM'},
    {'icon': Icons.location_on, 'title': 'Location Entry: Home', 'time': 'Today at 1:45 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Today', 'Week', 'Month'].map((String filter) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (bool selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.transparent),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: activityData.length,
                itemBuilder: (context, index) {
                  final item = activityData[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'], size: 24),
                    ),
                    title: Text(item['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text(item['time'], style: GoogleFonts.poppins(fontSize: 12)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
