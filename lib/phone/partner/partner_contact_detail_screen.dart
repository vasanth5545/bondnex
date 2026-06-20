// File: lib/partner_contact_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:bondnex/services/encryption/aes_encryption_service.dart';
import 'dart:convert';
import '../../models/call_log_model.dart';
import '../../phone/widgets/call_log_tile.dart';

class PartnerContactDetailScreen extends StatelessWidget {
  final String partnerId;
  final String contactName;
  final String contactNumber;

  const PartnerContactDetailScreen({
    super.key,
    required this.partnerId,
    required this.contactName,
    required this.contactNumber,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(contactName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                // FIXED: Wrapped the Column in an Expanded widget to prevent overflow.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        // ADDED: Prevent text from overflowing with an ellipsis.
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contactNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Call History",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getPartnerCallLogs(userProvider.firebaseUid, partnerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading call history.'),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('No call history with this contact.'),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final encryptedString = data?['encryptedPayload'] as String?;
                List<dynamic> rawLogs = [];

                if (encryptedString != null &&
                    encryptedString.isNotEmpty &&
                    userProvider.firebaseUid.isNotEmpty &&
                    userProvider.partnerId != null) {
                  return FutureBuilder<String>(
                    future: AesEncryptionService().decrypt(encryptedString, userProvider.partnerId!),
                    builder: (context, decryptSnapshot) {
                      if (decryptSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (decryptSnapshot.hasError || !decryptSnapshot.hasData || decryptSnapshot.data!.isEmpty) {
                        return const Center(child: Text('Decryption error or empty data.'));
                      }
                      
                      try {
                        rawLogs = jsonDecode(decryptSnapshot.data!) as List<dynamic>;
                      } catch (e) {
                        debugPrint('Error decoding logs: \$e');
                      }
                      
                      return _buildLogsList(rawLogs);
                    }
                  );
                } else {
                  rawLogs = data?['latest_call_logs'] as List<dynamic>? ?? [];
                  return _buildLogsList(rawLogs);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<dynamic> rawLogs) {
    if (rawLogs.isEmpty) {
      return const Center(
        child: Text('No call history with this contact.'),
      );
    }

    final callLogs = rawLogs
        .map(
          (map) =>
              CallLogEntry.fromMap(map as Map<String, dynamic>),
        )
        .where(
          (log) =>
              log.contact.phones.isNotEmpty &&
              log.contact.phones.first.number == contactNumber,
        )
        .toList();

    if (callLogs.isEmpty) {
      return const Center(
        child: Text('No call history with this contact.'),
      );
    }

    return ListView.builder(
      itemCount: callLogs.length,
      itemBuilder: (context, index) {
        return CallLogTile(log: callLogs[index]);
      },
    );
  }
}
