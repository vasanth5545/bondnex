// File: lib/partner_call_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'providers/user_provider.dart';
import 'phone/call_log_model.dart';
import 'phone/widgets/call_log_tile.dart';

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

                final callLogs = snapshot.data!.docs
                    .map((doc) => CallLogEntry.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: callLogs.length,
                  itemBuilder: (context, index) {
                    final log = callLogs[index];
                    if (log.isDeleted) {
                      return ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.grey),
                        title: Text(
                          'Call log deleted',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          'A call log from this time was deleted.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return CallLogTile(log: log);
                  },
                );
              },
            ),
    );
  }
}
