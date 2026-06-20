import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SimService {
  static const MethodChannel _channel = MethodChannel('com.bondnex.telephony');

  /// Retrieves available SIM cards from the device
  /// Returns a list of maps containing 'carrierName', 'displayName', 'slotIndex', 'subscriptionId'
  static Future<List<Map<String, dynamic>>> getSimCards() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getSimCards');
      if (result != null) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error getting SIM cards: $e");
    }
    return [];
  }

  /// Places a call using the specified SIM slot index (0 for SIM 1, 1 for SIM 2)
  static Future<bool> placeCallWithSim(String phoneNumber, int simSlotIndex) async {
    try {
      final bool? success = await _channel.invokeMethod('placeCallWithSim', {
        'phoneNumber': phoneNumber,
        'simSlotIndex': simSlotIndex,
      });
      return success ?? false;
    } catch (e) {
      debugPrint("Error placing call with SIM $simSlotIndex: $e");
      return false;
    }
  }
}
