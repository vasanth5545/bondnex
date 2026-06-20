import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:call_log/call_log.dart' as plugin_log;
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../database/database_helper.dart';
import '../database/firestore_service.dart';
import '../../models/call_log_model.dart';
import '../../firebase_options.dart';

const String syncCallLogsTask = 'sync_call_logs_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('WorkManager: Starting task $task');

      // 1. Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Check if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('WorkManager: No user logged in. Aborting sync.');
        return true;
      }
      final uid = currentUser.uid;

      // 3. Initialize Database
      final dbHelper = DatabaseHelper();
      await dbHelper.initDatabase();

      // 4. Fetch User Data to check if sharing is enabled
      final firestoreService = FirestoreService();
      final userDoc = await firestoreService.getUserData(uid);
      if (!userDoc.exists) return true;

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return true;

      final bool sharingEnabled = userData['callLogSharingEnabled'] ?? false;
      final String? partnerUid = userData['partner_uid'];

      if (!sharingEnabled || partnerUid == null || partnerUid.isEmpty) {
        debugPrint('WorkManager: Sharing disabled or no partner. Aborting sync.');
        return true;
      }

      // 5. Fetch new logs from device
      final lastLog = await dbHelper.getLatestCallLog();
      final lastTimestamp = lastLog?.timestamp.millisecondsSinceEpoch ?? 0;

      Iterable<plugin_log.CallLogEntry> newDeviceLogs =
          await plugin_log.CallLog.query(dateFrom: lastTimestamp);

      if (newDeviceLogs.isNotEmpty) {
        for (var deviceLog in newDeviceLogs) {
          final deviceTs = deviceLog.timestamp ?? 0;
          if (deviceTs == lastTimestamp && deviceTs != 0) continue;
          if (deviceTs == 0) continue;

          final log = CallLogEntry(
            id: deviceTs.toString() + (deviceLog.number ?? ''),
            contact: fc.Contact(
              displayName: deviceLog.name ?? 'Unknown',
              phones: [fc.Phone(deviceLog.number ?? '')],
            ),
            type: _convertCallType(deviceLog.callType),
            timestamp: DateTime.fromMillisecondsSinceEpoch(deviceTs),
            duration: Duration(seconds: deviceLog.duration ?? 0),
          );
          await dbHelper.insertCallLog(log);
        }
      }

      // 6. Sync to Firestore if there are unsynced logs
      final unsyncedLogs = await dbHelper.getUnsyncedCallLogs();
      if (unsyncedLogs.isNotEmpty) {
        final top10Logs = await dbHelper.getTop10LogsForSync();
        
        // This will handle the AES encryption inside uploadCallLogs
        await firestoreService.uploadCallLogs(uid, top10Logs);

        final idsToUpdate = unsyncedLogs.map((log) => log.id).toList();
        await dbHelper.markCallLogsAsSynced(idsToUpdate);
        debugPrint('WorkManager: Synced ${idsToUpdate.length} logs successfully.');
      } else {
        debugPrint('WorkManager: No unsynced logs.');
      }

      return true;
    } catch (e, stack) {
      debugPrint('WorkManager: Error in task $task: $e');
      debugPrint('WorkManager Stacktrace: $stack');
      return false; // Retries according to constraints
    }
  });
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

class WorkManagerService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    debugPrint('WorkManager initialized');
  }

  static void registerPeriodicSync() {
    Workmanager().registerPeriodicTask(
      'sync_call_logs_periodic',
      syncCallLogsTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    debugPrint('WorkManager periodic task registered');
  }
}
