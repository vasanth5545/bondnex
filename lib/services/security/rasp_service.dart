import 'package:cloud_functions/cloud_functions.dart';
import 'package:freerasp/freerasp.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class RaspService {
  static final RaspService _instance = RaspService._internal();
  factory RaspService() => _instance;
  RaspService._internal();

  bool isCompromised = false;

  Future<void> init() async {
    // Specify configs for Android
    final androidConfig = TalsecConfig(
      /// For Android
      androidConfig: AndroidConfig(
        packageName: 'com.bondnex.couple',
        signingCertHashes: [
          'ZMW6uN/KpGT0zWu+0wiYppDig4fNHa9DUiPwhACYhDs=',
        ], // Debug cert hash added. Update later for production
        supportedStores: ['com.sec.android.app.samsungapps'],
      ),

      /// For iOS
      iosConfig: IOSConfig(
        bundleIds: ['com.bondnex.couple'],
        teamId: 'YOUR_TEAM_ID', // TODO: Add team id for iOS
      ),
      watcherMail: 'vasanthvarman0@gmail.com',
      isProd: !kDebugMode,
    );

    final callback = ThreatCallback(
      onAppIntegrity: () => _handleThreat("App integrity compromised"),
      onObfuscationIssues: () => _handleThreat("Obfuscation issues"),
      onDebug: () => _handleThreat("Debugging detected"),
      onDeviceBinding: () => _handleThreat("Device binding compromised"),
      onDeviceID: () => _handleThreat("Device ID compromised"),
      onHooks: () => _handleThreat("Hooks (Frida) detected"),
      onPrivilegedAccess: () => _handleThreat("Root/Jailbreak detected"),
      onSecureHardwareNotAvailable: () =>
          _handleThreat("Secure hardware not available"),
      onSimulator: () => _handleThreat("Emulator detected"),
      onUnofficialStore: () => _handleThreat("Unofficial store detected"),
    );

    Talsec.instance.attachListener(callback);

    try {
      await Talsec.instance.start(androidConfig);
      debugPrint("RASP started successfully");
    } catch (e) {
      debugPrint("RASP start error: $e");
    }
  }

  Future<void> _handleThreat(String threat) async {
    debugPrint("Security Threat Detected: $threat");
    if (kReleaseMode) {
      isCompromised = true;
      try {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('reportSecurityThreat');
        await callable.call(<String, dynamic>{
          'reason': threat,
          // You could also add appVersion and deviceId here using package_info_plus and device_info_plus
        });
      } catch (e) {
        debugPrint("Failed to report threat to backend: $e");
      }
      
      exit(0); // Kill app on release mode if compromised
    }
  }
}
