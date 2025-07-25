// File: lib/phone/outgoing_call_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/call_log_provider.dart';
import '../providers/display_settings_provider.dart';
import 'call_log_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

class OutgoingCallScreen extends StatefulWidget {
  final fc.Contact contact;
  final String callType;

  const OutgoingCallScreen({
    super.key,
    required this.contact,
    required this.callType,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _endCall() {
    final callLogProvider = Provider.of<CallLogProvider>(context, listen: false);

    // This logic correctly creates a log entry. The provider handles the rest.
    final log = CallLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString() + (widget.contact.phones.isNotEmpty ? widget.contact.phones.first.number : ''),
      contact: widget.contact,
      type: CallType.outgoing,
      timestamp: DateTime.now(),
      duration: _stopwatch.elapsed,
      isSynced: false,
    );

    callLogProvider.addCallLog(log);

    Navigator.pop(context);
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
    return Consumer<DisplaySettingsProvider>(
      builder: (context, displaySettings, child) {
        final contactName = _formatContactName(widget.contact, displaySettings.sortOrder);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      CircleAvatar(
                        radius: 60,
                        child: const Icon(Icons.person, size: 60),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        contactName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.contact.phones.isNotEmpty ? widget.contact.phones.first.number : 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calling via ${widget.callType}...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCallControlButton(Icons.mic_off, 'Mute'),
                          _buildCallControlButton(Icons.volume_up, 'Speaker'),
                          _buildCallControlButton(Icons.dialpad, 'Keypad'),
                          _buildCallControlButton(Icons.pause, 'Hold'),
                        ],
                      ),
                      const SizedBox(height: 40),
                      FloatingActionButton(
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallControlButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }
}
