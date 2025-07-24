// File: lib/providers/call_log_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../phone/call_log_model.dart';
import '../services/database_helper.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

class CallLogProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();
  List<CallLogEntry> _callLogs = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  UserProvider _userProvider;

  List<CallLogEntry> get callLogs => _callLogs;

  List<CallLogEntry> get uniqueRecentCallLogs {
    final Map<String, CallLogEntry> uniqueLogs = {};
    for (final log in _callLogs) {
      final number = log.contact.phones.isNotEmpty 
          ? log.contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '') 
          : log.contact.displayName;
      if (number.isNotEmpty && !uniqueLogs.containsKey(number)) {
        uniqueLogs[number] = log;
      }
    }
    return uniqueLogs.values.toList();
  }

  CallLogProvider(this._userProvider) {
    _loadCallLogs();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        print("Network connection restored. Attempting to sync logs.");
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
  
  Future<void> _loadCallLogs() async {
    _callLogs = await _dbHelper.getCallLogs();
    notifyListeners();
  }

  Future<void> addCallLog(CallLogEntry log) async {
    await _dbHelper.insertCallLog(log);
    await _loadCallLogs();

    if (_userProvider.isLoggedIn && _userProvider.callLogSharingEnabled) {
      await syncPendingCallLogs();
    }
  }

  Future<void> deleteCallLog(String logId) async {
    await _dbHelper.markAsDeleted(logId);
    await _loadCallLogs();

    if (_userProvider.isLoggedIn && _userProvider.callLogSharingEnabled) {
      await syncPendingCallLogs();
    }
  }

  Future<void> syncPendingCallLogs() async {
    if (!_userProvider.isLoggedIn || !_userProvider.callLogSharingEnabled) {
      return;
    }

    final unsyncedLogs = await _dbHelper.getUnsyncedCallLogs();
    if (unsyncedLogs.isEmpty) {
      return;
    }

    try {
      for (final log in unsyncedLogs) {
        await _firestoreService.uploadCallLog(_userProvider.firebaseUid, log);
      }
      
      final idsToUpdate = unsyncedLogs.map((log) => log.id).toList();
      await _dbHelper.markCallLogsAsSynced(idsToUpdate);
      
      await _loadCallLogs();
      print("Successfully synced ${unsyncedLogs.length} call logs.");
    } catch (e) {
      print("Error syncing call logs: $e");
    }
  }
}
