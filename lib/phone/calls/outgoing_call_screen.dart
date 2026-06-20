import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:bondnex/services/telephony/call_manager_service.dart';

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
  bool _callLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchCall());
  }

  Future<void> _launchCall() async {
    final phoneNumber = widget.contact.phones.isNotEmpty
        ? widget.contact.phones.first.number
        : '';

    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() => _callLaunched = true);
    await CallManagerService().makeCall(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final contactName = widget.contact.displayName.isNotEmpty
        ? widget.contact.displayName
        : 'Unknown';
    final phoneNumber = widget.contact.phones.isNotEmpty
        ? widget.contact.phones.first.number
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                contactName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phoneNumber,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                _callLaunched ? 'Calling...' : 'Dialing...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              // End call button
              if (_callLaunched)
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () {
                    CallManagerService().hangupCall();
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
