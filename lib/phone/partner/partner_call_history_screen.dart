import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:bondnex/services/monetization/ad_manager.dart';
import 'package:bondnex/services/monetization/payment_service.dart';
import '../../providers/user_provider.dart';
import '../../models/call_log_model.dart';
import 'package:bondnex/phone/partner/partner_contact_detail_screen.dart';

class PartnerCallHistoryScreen extends StatefulWidget {
  const PartnerCallHistoryScreen({super.key});

  @override
  State<PartnerCallHistoryScreen> createState() =>
      _PartnerCallHistoryScreenState();
}

class _PartnerCallHistoryScreenState extends State<PartnerCallHistoryScreen> {
  final FirestoreService firestoreService = FirestoreService();

  String _maskPhoneNumber(String number) {
    if (number == 'Unknown' || number.length <= 2) return number;
    return number.substring(0, 2) + '*' * (number.length - 2);
  }

  void _showUnlockDialog(
    BuildContext context,
    String number,
    String name,
    String partnerId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Unlock Call History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to unlock this phone number.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch 3 Ads (Free)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _processAdUnlock(context, number, name, partnerId);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.star),
              label: const Text('Get Premium (Instant)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _processPremiumUnlock(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processPremiumUnlock(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    PaymentService().init();
    await PaymentService().openCheckout(
      "14_days",
      "${user.firebaseUid}@bondnex.com",
      "",
    );
  }

  Future<void> _processAdUnlock(
    BuildContext context,
    String number,
    String name,
    String partnerId,
  ) async {
    AdManager().init();
    AdManager().loadRewardedAd();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context); // pop loading

    AdManager().showRewardedAd(number, (isUnlocked, adsWatched) {
      if (!context.mounted) return;
      if (isUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number Unlocked Successfully!')),
        );
        _navigateToDetail(context, number, name, partnerId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ad Watched! $adsWatched / 3 completed.')),
        );
      }
    });
  }

  Future<bool> _checkBackendUnlock(
    BuildContext context,
    String number,
    String name,
    String partnerId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'revealPhoneNumber',
      );
      await callable.call({'targetPhoneNumber': number});
      if (!context.mounted) return true;
      Navigator.pop(context); // pop loading
      _navigateToDetail(context, number, name, partnerId);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      Navigator.pop(context); // pop loading
      return false;
    }
  }

  void _navigateToDetail(
    BuildContext context,
    String number,
    String name,
    String partnerId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerContactDetailScreen(
          partnerId: partnerId,
          contactName: name,
          contactNumber: number,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("${userProvider.partnerName ?? 'Partner'}'s Call History"),
      ),
      body: userProvider.partnerId == null
          ? const Center(child: Text('You are not connected to a partner.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getPartnerCallLogs(
                userProvider.partnerId!,
                userProvider.firebaseUid,
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
                List<dynamic> rawLogs =
                    data?['latest_call_logs'] as List<dynamic>? ?? [];

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
                    final originalNumber = contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'Unknown';
                    final maskedNumber = _maskPhoneNumber(originalNumber);

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(contact.displayName),
                      subtitle: Text(
                        maskedNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.lock_outline,
                        color: Colors.blue,
                      ),
                      onTap: () async {
                        if (originalNumber == 'Unknown') {
                          _navigateToDetail(
                            context,
                            originalNumber,
                            contact.displayName,
                            userProvider.partnerId!,
                          );
                          return;
                        }

                        final isUnlocked = await _checkBackendUnlock(
                          context,
                          originalNumber,
                          contact.displayName,
                          userProvider.partnerId!,
                        );
                        if (!isUnlocked) {
                          if (!context.mounted) return;
                          _showUnlockDialog(
                            context,
                            originalNumber,
                            contact.displayName,
                            userProvider.partnerId!,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
