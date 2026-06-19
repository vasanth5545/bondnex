// File: lib/partner_call_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/firestore_service.dart';
import 'providers/user_provider.dart';
import 'phone/call_log_model.dart';
import 'partner_contact_detail_screen.dart'; // NEW: Import the new detail screen

class PartnerCallHistoryScreen extends StatelessWidget {
  const PartnerCallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text("${userProvider.partnerName ?? 'Partner'}'s Call History"),
      ),
      body: userProvider.partnerId == null
          ? const Center(child: Text('You are not connected to a partner.'))
          : StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getPartnerCallLogs(userProvider.partnerId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No call history found.'));
                }

                // MODIFIED: Process logs to get a list of unique contacts
                final allLogs = snapshot.data!.docs
                    .map((doc) => CallLogEntry.fromFirestore(doc))
                    .toList();

                final Map<String, CallLogEntry> uniqueContactsMap = {};
                for (var log in allLogs) {
                  final number = log.contact.phones.isNotEmpty ? log.contact.phones.first.number : 'Unknown';
                  if (number != 'Unknown' && !uniqueContactsMap.containsKey(number)) {
                    uniqueContactsMap[number] = log;
                  }
                }
                final uniqueContacts = uniqueContactsMap.values.toList();

                return ListView.builder(
                  itemCount: uniqueContacts.length,
                  itemBuilder: (context, index) {
                    final log = uniqueContacts[index];
                    final contact = log.contact;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No number'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // NEW: Navigate to the new detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PartnerContactDetailScreen(
                              partnerId: userProvider.partnerId!,
                              contactName: contact.displayName,
                              contactNumber: contact.phones.isNotEmpty ? contact.phones.first.number : 'Unknown',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
