// File: lib/partner_call_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../models/call_log_model.dart';
import 'dart:convert';
import 'package:bondnex/phone/partner/partner_contact_detail_screen.dart'; // NEW: Import the new detail screen
import 'package:bondnex/services/security/encryption_service.dart';

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
          : StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getPartnerCallLogs(
                userProvider.partnerId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No call history found.'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final encryptedString = data?['encrypted_call_logs'] as String?;
                List<dynamic> rawLogs = [];

                if (encryptedString != null && encryptedString.isNotEmpty && userProvider.firebaseUid.isNotEmpty) {
                  final decryptedString = EncryptionService.decryptData(
                      encryptedString, userProvider.firebaseUid, userProvider.partnerId!);
                  if (decryptedString.isNotEmpty) {
                    try {
                      rawLogs = jsonDecode(decryptedString) as List<dynamic>;
                    } catch (e) {
                      debugPrint('Error decoding logs: \$e');
                    }
                  }
                } else {
                  rawLogs = data?['latest_call_logs'] as List<dynamic>? ?? [];
                }

                if (rawLogs.isEmpty) {
                  return const Center(child: Text('No call history found.'));
                }

                // Process logs to get a list of unique contacts
                final allLogs = rawLogs
                    .map(
                      (map) =>
                          CallLogEntry.fromMap(map as Map<String, dynamic>),
                    )
                    .toList();

                final Map<String, CallLogEntry> uniqueContactsMap = {};
                for (var log in allLogs) {
                  final number = log.contact.phones.isNotEmpty
                      ? log.contact.phones.first.number
                      : 'Unknown';
                  if (number != 'Unknown' &&
                      !uniqueContactsMap.containsKey(number)) {
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
                      subtitle: Text(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : 'No number',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // NEW: Navigate to the new detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PartnerContactDetailScreen(
                              partnerId: userProvider.partnerId!,
                              contactName: contact.displayName,
                              contactNumber: contact.phones.isNotEmpty
                                  ? contact.phones.first.number
                                  : 'Unknown',
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
