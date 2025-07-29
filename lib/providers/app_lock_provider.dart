// File: lib/providers/app_lock_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockProvider extends ChangeNotifier {
  bool _isAppLockEnabled = false;
  bool _isFingerprintEnabled = false;
  String? _pin;
  String _autoLockTimer = 'Immediate';

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isFingerprintEnabled => _isFingerprintEnabled;
  String? get pin => _pin;
  String get autoLockTimer => _autoLockTimer;

  AppLockProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool('appLockEnabled') ?? false;
    _isFingerprintEnabled = prefs.getBool('fingerprintEnabled') ?? false;
    _pin = prefs.getString('pin');
    _autoLockTimer = prefs.getString('autoLockTimer') ?? 'Immediate';
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _isAppLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLockEnabled', value);
    notifyListeners();
  }

  Future<void> setFingerprintEnabled(bool value) async {
    _isFingerprintEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fingerprintEnabled', value);
    notifyListeners();
  }

  Future<void> setPin(String newPin) async {
    _pin = newPin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', newPin);
    notifyListeners();
  }

  Future<void> setAutoLockTimer(String timer) async {
    _autoLockTimer = timer;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoLockTimer', timer);
    notifyListeners();
  }
}
