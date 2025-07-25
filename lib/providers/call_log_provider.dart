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
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProvider _userProvider;

  List<CallLogEntry> get callLogs => _callLogs;
  bool get isLoading => _isLoading;

  CallLogProvider(this._userProvider) {
    // _loadCallLogs(); // REMOVED: Don't load automatically
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
  
  // MODIFIED: Renamed from _loadCallLogs and made public
  Future<void> loadCallLogs() async {
    if (_isInitialized || _isLoading) return; // Prevent multiple loads
    _isLoading = true;
    notifyListeners();

    _callLogs = await _dbHelper.getCallLogs();
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCallLog(CallLogEntry log) async {
    await _dbHelper.insertCallLog(log);
    // Instead of full reload, just add to the list to be faster
    _callLogs.insert(0, log);
    notifyListeners();

    if (_userProvider.isLoggedIn && _userProvider.callLogSharingEnabled) {
      await syncPendingCallLogs();
    }
  }

  Future<void> deleteCallLog(String logId) async {
    await _dbHelper.markAsDeleted(logId);
    // Instead of full reload, just remove from the list
    _callLogs.removeWhere((log) => log.id == logId);
    notifyListeners();

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
      
      // No need to call _loadCallLogs() as the local list is already updated.
      print("Successfully synced ${unsyncedLogs.length} call logs.");
    } catch (e) {
      print("Error syncing call logs: $e");
    }
  }
}
