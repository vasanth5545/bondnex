// File: lib/settings/panic_button_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
// **THE FIX IS HERE** - Using the new url_launcher package
import 'package:url_launcher/url_launcher.dart';

class PanicButtonSettingsScreen extends StatefulWidget {
  const PanicButtonSettingsScreen({super.key});

  @override
  State<PanicButtonSettingsScreen> createState() => _PanicButtonSettingsScreenState();
}

enum TriggerMethod { volume, power, inApp }

class _PanicButtonSettingsScreenState extends State<PanicButtonSettingsScreen> {
  bool _isPanicEnabled = false;
  TriggerMethod? _selectedMethod = TriggerMethod.volume;
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _messageController = TextEditingController(text: "Emergency! I need help. This is my current location.");

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      Contact? contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        setState(() {
          _contactController.text = contact.phones.first.number;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact permission is required to pick a contact.')),
      );
    }
  }

  // **THE FIX IS HERE** - Updated function to use url_launcher
  Future<void> _sendTestSms(String message, String recipient) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: <String, String>{
        'body': Uri.encodeComponent(message),
      },
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch SMS app.')),
      );
    }
  }

  void _testPanicButton() {
    if (_contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an emergency contact first.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Alert'),
        content: Text('This will open your SMS app to send a test message to "${_contactController.text}". Do you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendTestSms("[TEST] ${_messageController.text}", _contactController.text);
            },
            child: const Text('Open SMS App'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Panic Button'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Panic Button'),
              SwitchListTile(
                title: Text('Enable Panic Button', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Enable the panic button for quick access in case of emergency.', style: GoogleFonts.poppins(color: Colors.grey[500])),
                value: _isPanicEnabled,
                onChanged: (value) => setState(() => _isPanicEnabled = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Trigger Method'),
              _buildRadioTile('Long Press Volume Key', TriggerMethod.volume),
              _buildRadioTile('Double Tap Power Button', TriggerMethod.power),
              _buildRadioTile('In-App Button', TriggerMethod.inApp),
              const SizedBox(height: 24),

              _buildSectionHeader('Emergency Contact'),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  hintText: 'Enter phone number or pick from contacts',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contact_phone_outlined),
                    onPressed: _pickContact,
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('SOS Message'),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter custom SOS message',
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Test Panic Button'),
              ElevatedButton(
                onPressed: _testPanicButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                child: const Text('Test Panic Button'),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Save/Update'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRadioTile(String title, TriggerMethod value) {
    return RadioListTile<TriggerMethod>(
      title: Text(title),
      value: value,
      groupValue: _selectedMethod,
      onChanged: (TriggerMethod? newValue) {
        setState(() {
          _selectedMethod = newValue;
        });
      },
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
