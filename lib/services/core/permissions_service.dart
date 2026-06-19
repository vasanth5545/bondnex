import 'package:permission_handler/permission_handler.dart';

/// A service class to handle all permission requests.
class PermissionsService {
  /// Requests necessary permissions for the dialer feature.
  ///
  /// Returns `true` if all permissions are granted, `false` otherwise.
  Future<bool> requestDialerPermissions() async {
    // Requesting the 'phone' permission group covers READ_CALL_LOG.
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }
}
