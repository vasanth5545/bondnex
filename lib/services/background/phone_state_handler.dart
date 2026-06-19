import 'package:flutter/material.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:call_log/call_log.dart' as plugin_log;
import 'package:bondnex/services/database/database_helper.dart';
import 'package:bondnex/models/call_log_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bondnex/services/database/firestore_service.dart';

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
  PhoneStateBackgroundEvent event,
  String number,
  int duration,
) async {
  debugPrint("Background Call Event: $event, Number: $number, Duration: $duration");
  
  // We only care when the call ends.
  if (event == PhoneStateBackgroundEvent.incomingend ||
      event == PhoneStateBackgroundEvent.incomingmissed ||
      event == PhoneStateBackgroundEvent.outgoingend) {
        
    // Wait a brief moment to allow Android to write the log to the native database.
    await Future.delayed(const Duration(seconds: 3));
    
    try {
      // 1. Fetch the latest call log from the device.
      Iterable<plugin_log.CallLogEntry> newDeviceLogs =
          await plugin_log.CallLog.query(dateFrom: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch);
          
      if (newDeviceLogs.isNotEmpty) {
        // The first one is usually the most recent. Let's find the one that matches our ended call roughly.
        var deviceLog = newDeviceLogs.first;
        
        final log = CallLogEntry(
          id: deviceLog.timestamp.toString() + (deviceLog.number ?? ''),
          contact: fc.Contact(
            displayName: deviceLog.name ?? 'Unknown',
            phones: [fc.Phone(deviceLog.number ?? '')],
          ),
          type: _convertCallType(deviceLog.callType),
          timestamp: DateTime.fromMillisecondsSinceEpoch(deviceLog.timestamp ?? 0),
          duration: Duration(seconds: deviceLog.duration ?? 0),
        );

        // 2. Save it to our local SQLite DB.
        final dbHelper = DatabaseHelper();
        await dbHelper.insertCallLog(log);
        debugPrint("Background: Call log successfully saved to SQLite.");

        // 3. Try to sync to Firebase if the user has it enabled.
        await _trySyncToFirebase(dbHelper);
      }
    } catch (e) {
      debugPrint("Background: Error fetching or saving call log: $e");
    }
  }
}

CallType _convertCallType(plugin_log.CallType? type) {
  switch (type) {
    case plugin_log.CallType.incoming:
      return CallType.incoming;
    case plugin_log.CallType.outgoing:
      return CallType.outgoing;
    case plugin_log.CallType.missed:
      return CallType.missed;
    default:
      return CallType.missed;
  }
}

Future<void> _trySyncToFirebase(DatabaseHelper dbHelper) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userUid = prefs.getString('user_uid');
    final sharingEnabled = prefs.getBool('callLogSharingEnabled') ?? true;

    if (userUid != null && userUid.isNotEmpty && sharingEnabled) {
      // Initialize Firebase if not already initialized in this isolate.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final firestoreService = FirestoreService();
      final unsyncedLogs = await dbHelper.getUnsyncedCallLogs();
      
      if (unsyncedLogs.isNotEmpty) {
        final top10Logs = await dbHelper.getTop10LogsForSync();
        await firestoreService.uploadCallLogs(userUid, top10Logs);

        final idsToUpdate = unsyncedLogs.map((l) => l.id).toList();
        await dbHelper.markCallLogsAsSynced(idsToUpdate);
        debugPrint("Background: Successfully synced call log array to Firebase.");
      }
    }
  } catch (e) {
    debugPrint("Background: Firebase sync failed (will retry on next app open): $e");
  }
}
