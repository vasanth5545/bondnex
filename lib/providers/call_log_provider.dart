// File: lib/providers/call_log_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart' as plugin_log;
import '../models/call_log_model.dart';
import 'package:bondnex/services/database/database_helper.dart';
import 'package:bondnex/services/database/firestore_service.dart';
import 'package:bondnex/services/background/phone_state_handler.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'user_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

class CallLogProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();
  List<CallLogEntry> _callLogs = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProvider _userProvider;

  List<CallLogEntry> get callLogs => _callLogs;
  bool get isLoading => _isLoading;

  CallLogProvider(this._userProvider) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        debugPrint("Network connection restored. Attempting to sync logs.");
        syncPendingCallLogs();
      }
    });
  }

  void updateUserProvider(UserProvider newUserProvider) {
    _userProvider = newUserProvider;
    syncPendingCallLogs();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Loads logs from DB first for speed, then syncs device logs in the background.
  Future<void> initializeCallLogs() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    // 1. Load from local DB first for instant UI update.
    await loadCallLogsFromDb();
    _isLoading = false;
    notifyListeners();

    // 2. Initialize Background Phone State capturing
    await _initBackgroundPhoneState();

    // 3. Then, sync with the device in the background.
    await syncDeviceLogsToDb();
    _isInitialized = true;
  }

  Future<void> _initBackgroundPhoneState() async {
    try {
      final hasPermission = await PhoneStateBackground.checkPermission();
      if (!hasPermission) {
        await PhoneStateBackground.requestPermissions();
      }
      await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
    } catch (e) {
      debugPrint("Error initializing background phone state: $e");
    }
  }

  /// Fetches new logs from the device and saves them to the local DB.
  Future<void> syncDeviceLogsToDb() async {
    // Only proceed if the user is logged in
    if (!_userProvider.isLoggedIn) {
      return;
    }

    var status = await Permission.phone.status;
    if (!status.isGranted) {
      debugPrint("Permission not granted. Cannot sync call logs.");
      return;
    }

    try {
      final lastLog = await _dbHelper.getLatestCallLog();
      final lastTimestamp = lastLog?.timestamp.millisecondsSinceEpoch ?? 0;

      Iterable<plugin_log.CallLogEntry> newDeviceLogs =
          await plugin_log.CallLog.query(dateFrom: lastTimestamp);

      if (newDeviceLogs.isNotEmpty) {
        for (var deviceLog in newDeviceLogs) {
          // Avoid re-inserting the very last log we already have
          if (deviceLog.timestamp == lastTimestamp) continue;

          final log = CallLogEntry(
            id: deviceLog.timestamp.toString() + (deviceLog.number ?? ''),
            contact: fc.Contact(
              displayName: deviceLog.name ?? 'Unknown',
              phones: [fc.Phone(deviceLog.number ?? '')],
            ),
            type: _convertCallType(deviceLog.callType),
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              deviceLog.timestamp ?? 0,
            ),
            duration: Duration(seconds: deviceLog.duration ?? 0),
          );
          await _dbHelper.insertCallLog(log);
        }

        // Refresh UI from DB and sync to Firestore
        await loadCallLogsFromDb();
        await syncPendingCallLogs();
      }
    } catch (e) {
      debugPrint("Error syncing device logs: $e");
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

  Future<void> loadCallLogsFromDb() async {
    _callLogs = await _dbHelper.getCallLogs();
    notifyListeners();
  }

  Future<void> addCallLog(CallLogEntry log) async {
    await _dbHelper.insertCallLog(log);
    _callLogs.insert(0, log);
    notifyListeners();

    if (_userProvider.isLoggedIn && _userProvider.callLogSharingEnabled) {
      await syncPendingCallLogs();
    }
  }

  Future<void> deleteCallLog(String logId) async {
    await _dbHelper.markAsDeleted(logId);
    _callLogs.removeWhere((log) => log.id == logId);
    notifyListeners();

    if (_userProvider.isLoggedIn && _userProvider.callLogSharingEnabled) {
      await syncPendingCallLogs();
    }
  }

  // UPDATED: This function syncs the absolute latest 10 calls to a single array in Firebase.
  Future<void> syncPendingCallLogs() async {
    if (!_userProvider.isLoggedIn ||
        !_userProvider.callLogSharingEnabled ||
        !_userProvider.isPartnerConnected) {
      return;
    }

    final unsyncedLogs = await _dbHelper.getUnsyncedCallLogs();
    if (unsyncedLogs.isEmpty) {
      return;
    }

    // Fetch the top 10 most recent logs overall, regardless of sync status.
    final top10Logs = await _dbHelper.getTop10LogsForSync();

    try {
      // Upload the single array to the user document.
      await _firestoreService.uploadCallLogs(
        _userProvider.firebaseUid,
        top10Logs,
      );

      // Mark the previously unsynced logs as synced so we don't sync again until new changes occur.
      final idsToUpdate = unsyncedLogs.map((log) => log.id).toList();
      await _dbHelper.markCallLogsAsSynced(idsToUpdate);
      debugPrint(
        "Successfully synced latest call log array. Marked ${idsToUpdate.length} logs as synced locally.",
      );
    } catch (e) {
      debugPrint("Error syncing call logs: $e");
    }
  }
}
