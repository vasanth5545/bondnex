// File: lib/phone/contact_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'save_contact_screen.dart';
import '../providers/call_log_provider.dart';
import '../providers/display_settings_provider.dart';
import 'widgets/call_log_tile.dart';

class ContactDetailsScreen extends StatelessWidget {
  final fc.Contact contact;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
  });
  
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
    return Consumer2<CallLogProvider, DisplaySettingsProvider>(
      builder: (context, callLogProvider, displaySettings, child) {
        final contactLogs = callLogProvider.callLogs.where((log) {
          final logNumber = log.contact.phones.isNotEmpty 
              ? log.contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '') 
              : null;
          final contactNumber = contact.phones.isNotEmpty 
              ? contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '') 
              : null;
          return logNumber != null && contactNumber != null && logNumber == contactNumber;
        }).toList();
        
        final contactName = _formatContactName(contact, displaySettings.sortOrder);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SaveContactScreen(contact: contact),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Contact updated successfully!')),
                      );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 60),
              ),
              const SizedBox(height: 16),
              Text(
                contactName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.call, 'Call'),
                  _buildActionButton(Icons.message, 'Message'),
                  _buildActionButton(Icons.video_call, 'Video'),
                  _buildActionButton(Icons.mail, 'Mail'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    children: [
                      _buildSectionTitle('Contact info'),
                      if (contact.phones.isNotEmpty)
                        _buildContactInfo(Icons.call, contact.phones.first.number, 'Mobile'),
                      if (contact.emails.isNotEmpty)
                        _buildContactInfo(Icons.mail, contact.emails.first.address, 'Home'),
                      if (contact.addresses.isNotEmpty)
                        _buildContactInfo(Icons.location_on, contact.addresses.first.address, ''),
                       if (contact.organizations.isNotEmpty)
                        _buildContactInfo(Icons.business, contact.organizations.first.company, 'Work'),
                      if (contact.notes.isNotEmpty)
                        _buildContactInfo(Icons.note, contact.notes.first.note, ''),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Recent calls'),
                      if (contactLogs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No recent calls with this contact.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...contactLogs.map((log) => CallLogTile(log: log)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[800],
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey)) : null,
    );
  }
}
