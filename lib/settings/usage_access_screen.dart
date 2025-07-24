// File: lib/settings/usage_access_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_usage/app_usage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

class UsageAccessScreen extends StatefulWidget {
  const UsageAccessScreen({super.key});

  @override
  State<UsageAccessScreen> createState() => _UsageAccessScreenState();
}

class _UsageAccessScreenState extends State<UsageAccessScreen> {
  bool _enableTracking = false;
  bool _enableLimitNotifications = false;
  List<AppUsageInfo> _usageInfo = [];
  final AppUsage _appUsage = AppUsage();

  @override
  void initState() {
    super.initState();
    if (_enableTracking) {
      getUsageStats();
    }
  }

  void getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 24));
      List<AppUsageInfo> info = await _appUsage.getAppUsage(startDate, endDate);
      setState(() {
        _usageInfo = info;
      });
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  void _openUsageSettings() {
    if (Platform.isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      intent.launch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is only available on Android.')),
      );
    }
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}h ${twoDigitMinutes}m";
    } else {
      return "${d.inMinutes}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Usage Access'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchTile(
                title: 'Enable App Usage Tracking',
                subtitle: 'Allow this app to read which apps you use & how long you use them.',
                value: _enableTracking,
                onChanged: (value) {
                  setState(() => _enableTracking = value);
                  if (value) {
                    getUsageStats();
                  } else {
                    setState(() => _usageInfo = []);
                  }
                },
              ),
              const SizedBox(height: 24),

              Text('Tracked Apps', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _enableTracking ? _buildAppUsageList() : _buildDisabledMessage(),
              const SizedBox(height: 24),

              Text('Usage Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(height: 150, child: _buildDailyUsageChart()),
              const SizedBox(height: 16),
              Center(child: Text("Today's most used app: WhatsApp", style: GoogleFonts.poppins(color: Colors.grey[500]))),
              const SizedBox(height: 24),

              _buildSwitchTile(
                title: 'Usage Limit Notifications',
                subtitle: 'Notify partner if usage crosses limit (e.g., 1 hour)',
                value: _enableLimitNotifications,
                onChanged: (value) => setState(() => _enableLimitNotifications = value),
              ),
              const SizedBox(height: 24),

              // **THE FIX IS HERE** - Reordered to match your new UI
              Text('Manage Permission', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'To track which apps you use, this app needs permission. Please grant it in your phone\'s system settings.',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _openUsageSettings,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Open System Settings'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Required for usage tracking features to work properly.',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                child: const Text('Choose Apps to Track'),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Update'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[500])),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  // **THE FIX IS HERE** - Helper function to get specific icons for apps
  IconData _getAppIcon(String appName) {
    if (appName.toLowerCase().contains('whatsapp')) return Icons.chat;
    if (appName.toLowerCase().contains('instagram')) return Icons.camera_alt;
    if (appName.toLowerCase().contains('facebook')) return Icons.facebook;
    if (appName.toLowerCase().contains('tiktok')) return Icons.music_note;
    if (appName.toLowerCase().contains('snapchat')) return Icons.child_care;
    return Icons.apps; // Default icon
  }

  Widget _buildAppUsageList() {
    // Using dummy data for display as real data requires permissions and time.
    final dummyApps = [
      {'name': 'WhatsApp', 'usage': const Duration(hours: 1, minutes: 20)},
      {'name': 'Instagram', 'usage': const Duration(minutes: 45)},
      {'name': 'Facebook', 'usage': const Duration(minutes: 30)},
      {'name': 'TikTok', 'usage': const Duration(minutes: 20)},
      {'name': 'Snapchat', 'usage': const Duration(minutes: 15)},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dummyApps.length,
      itemBuilder: (context, index) {
        final app = dummyApps[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getAppIcon(app['name'] as String)),
          ),
          title: Text(app['name'] as String),
          trailing: Text(formatDuration(app['usage'] as Duration)),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        );
      },
    );
  }

  Widget _buildDisabledMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('Enable tracking to see app list.')),
    );
  }

  Widget _buildDailyUsageChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          _makeBarData(0, 5),
          _makeBarData(1, 2),
          _makeBarData(2, 2.5),
          _makeBarData(3, 4),
          _makeBarData(4, 8),
          _makeBarData(5, 1.5),
          _makeBarData(6, 3),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 10,
                );
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Mon'; break;
                  case 1: text = 'Tue'; break;
                  case 2: text = 'Wed'; break;
                  case 3: text = 'Thu'; break;
                  case 4: text = 'Fri'; break;
                  case 5: text = 'Sat'; break;
                  case 6: text = 'Sun'; break;
                  default: text = ''; break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(text, style: style),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: Theme.of(context).colorScheme.primary,
        width: 15,
        borderRadius: BorderRadius.circular(4),
      ),
    ]);
  }
}
