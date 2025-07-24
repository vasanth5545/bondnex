// File: lib/phone/call_log_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/display_settings_provider.dart';
import 'call_log_model.dart';
import 'outgoing_call_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

class CallLogDetailsScreen extends StatelessWidget {
  final CallLogEntry? log; // Make log optional
  const CallLogDetailsScreen({super.key, this.log});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  String _formatContactName(fc.Contact contact, NameSortOrder sortOrder) {
    if (contact.displayName.isEmpty) {
      return contact.phones.isNotEmpty ? contact.phones.first.number : 'Unknown';
    }
    if (sortOrder == NameSortOrder.lastNameFirst) {
      return '${contact.name.last} ${contact.name.first}'.trim();
    }
    return contact.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final CallLogEntry? callLog = log ?? ModalRoute.of(context)?.settings.arguments as CallLogEntry?;

    if (callLog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Call log details not found.")),
      );
    }
    
    return Consumer<DisplaySettingsProvider>(
      builder: (context, displaySettings, child) {
        final contactName = _formatContactName(callLog.contact, displaySettings.sortOrder);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Call Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(contactName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(callLog.contact.phones.isNotEmpty ? callLog.contact.phones.first.number : 'No number'),
                ),
                const Divider(),
                _buildDetailRow(Icons.timer, 'Duration', _formatDuration(callLog.duration)),
                _buildDetailRow(Icons.calendar_today, 'Date', DateFormat.yMMMMd().format(callLog.timestamp)),
                _buildDetailRow(Icons.access_time, 'Time', DateFormat.jm().format(callLog.timestamp)),
                _buildDetailRow(
                  callLog.type == CallType.incoming ? Icons.call_received :
                  callLog.type == CallType.outgoing ? Icons.call_made : Icons.call_missed,
                  'Type',
                  callLog.type.toString().split('.').last,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OutgoingCallScreen(
                          contact: callLog.contact,
                          callType: 'SIM',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call Back'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.poppins(fontSize: 16)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
