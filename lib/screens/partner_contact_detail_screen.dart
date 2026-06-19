// File: lib/partner_contact_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'phone/call_log_model.dart';
import 'phone/widgets/call_log_tile.dart';

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
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(contactName),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                const SizedBox(width: 16),
                // FIXED: Wrapped the Column in an Expanded widget to prevent overflow.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                        // ADDED: Prevent text from overflowing with an ellipsis.
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contactNumber,
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
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
            child: Text("Call History", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getPartnerCallLogsForNumber(partnerId, contactNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // FIXED: Handle potential Firestore errors gracefully.
                if (snapshot.hasError) {
                    return const Center(child: Text('Error loading call history. Please ensure the Firestore index is created.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No call history with this contact.'));
                }

                final callLogs = snapshot.data!.docs
                    .map((doc) => CallLogEntry.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: callLogs.length,
                  itemBuilder: (context, index) {
                    return CallLogTile(log: callLogs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
