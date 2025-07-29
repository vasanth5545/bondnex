import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
// Assuming PermissionsService and FirestoreService are in your project and imported.
// import '../services/permissions_service.dart';
// import '../services/firestore_service_dialer.dart';


class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  // Uncomment these lines once you have the service files in your project
  // final PermissionsService _permissionsService = PermissionsService();
  // final FirestoreService _firestoreService = FirestoreService();
  bool _hasPermission = false;
  bool _isLoading = true;
  Iterable<CallLogEntry> _callLogs = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetchLogs();
  }

  Future<void> _checkPermissionAndFetchLogs() async {
    // Using the permission logic directly for this example
    final bool isGranted = await _requestDialerPermissions();
    setState(() {
      _hasPermission = isGranted;
    });

    if (isGranted) {
      await _loadAndSyncCallLogs();
    } else {
       setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestDialerPermissions() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }


  Future<void> _loadAndSyncCallLogs() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch logs directly from the device using the plugin
    Iterable<CallLogEntry> logs = await CallLog.get();

    setState(() {
      _callLogs = logs;
      _isLoading = false;
    });

    // Save the fetched logs to Firestore
    // Replace 'currentUserId' with the actual logged-in user's ID from your UserProvider
    // await _firestoreService.saveCallLogs('currentUserId', logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasPermission
              ? ListView.builder(
                  itemCount: _callLogs.length,
                  itemBuilder: (context, index) {
                    final log = _callLogs.elementAt(index);
                    return ListTile(
                      title: Text(log.name ?? log.number ?? 'Unknown'),
                      subtitle: Text(
                          '${log.callType.toString().split('.').last} - ${DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0)}'),
                      trailing: Text('${log.duration}s'),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Call Log permission is required to use this feature."),
                      ElevatedButton(
                        onPressed: openAppSettings,
                        child: const Text("Open Settings"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
