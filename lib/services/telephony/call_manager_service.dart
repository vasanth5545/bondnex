import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

enum CallState { idle, dialing, ringing, active, disconnected, error }

class NativeCall {
  final String id;
  final String number;
  final CallState state;
  final int duration; // in seconds

  NativeCall({
    required this.id,
    required this.number,
    this.state = CallState.idle,
    this.duration = 0,
  });

  factory NativeCall.fromMap(Map<String, dynamic> map) {
    CallState parsedState = CallState.idle;
    switch (map['state'] as String?) {
      case 'DIALING':
        parsedState = CallState.dialing;
        break;
      case 'RINGING':
        parsedState = CallState.ringing;
        break;
      case 'ACTIVE':
        parsedState = CallState.active;
        break;
      case 'DISCONNECTED':
        parsedState = CallState.disconnected;
        break;
      default:
        parsedState = CallState.idle;
    }

    return NativeCall(
      id: map['id'] ?? '',
      number: map['number'] ?? '',
      state: parsedState,
      duration: map['duration'] ?? 0,
    );
  }

  NativeCall copyWith({CallState? state, int? duration}) {
    return NativeCall(
      id: id,
      number: number,
      state: state ?? this.state,
      duration: duration ?? this.duration,
    );
  }
}

class CallManagerService extends ChangeNotifier {
  static final CallManagerService _instance = CallManagerService._internal();
  factory CallManagerService() => _instance;
  CallManagerService._internal();

  static const MethodChannel _methodChannel = MethodChannel('com.bondnex/dialer');
  static const EventChannel _eventChannel = EventChannel('com.bondnex/call_events');

  NativeCall? _currentCall;
  NativeCall? get currentCall => _currentCall;

  String _status = 'Idle';
  String get status => _status;

  bool _isInitialized = false;
  StreamSubscription? _eventSubscription;

  Future<void> init() async {
    if (_isInitialized) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(_onCallEvent);
    
    _isInitialized = true;
  }

  void _onCallEvent(dynamic event) {
    if (event is Map) {
      final String type = event['type'] ?? '';
      
      if (type == 'call_added' || type == 'call_updated') {
        _currentCall = NativeCall.fromMap(Map<String, dynamic>.from(event['call']));
        _status = 'Call state: ${_currentCall?.state.name}';
        notifyListeners();
      } else if (type == 'call_removed') {
        _currentCall = null;
        _status = 'Call ended.';
        notifyListeners();
        
        // Trigger immediate sync via WorkManager
        try {
          Workmanager().registerOneOffTask(
            'sync_call_after_disconnect',
            'sync_call_logs_task',
          );
        } catch (e) {
          debugPrint('Failed to register one-off sync task: $e');
        }
      }
    }
  }

  Future<bool> isDefaultDialer() async {
    try {
      final bool result = await _methodChannel.invokeMethod('isDefaultDialer');
      return result;
    } catch (e) {
      debugPrint('Error checking default dialer: $e');
      return false;
    }
  }

  Future<bool> requestDefaultDialer() async {
    try {
      final bool result = await _methodChannel.invokeMethod('requestDefaultDialer');
      return result;
    } catch (e) {
      debugPrint('Error requesting default dialer: $e');
      return false;
    }
  }

  Future<void> makeCall(String phoneNumber, {int? simSlotIndex}) async {
    try {
      _status = 'Dialing...';
      notifyListeners();
      await _methodChannel.invokeMethod('makeCall', {
        'number': phoneNumber,
      });
    } catch (e) {
      _status = 'Error making call: $e';
      notifyListeners();
    }
  }

  Future<void> answerCall() async {
    try {
      await _methodChannel.invokeMethod('answerCall');
    } catch (e) {
      debugPrint('Error answering call: $e');
    }
  }

  Future<void> declineCall() async {
    try {
      await _methodChannel.invokeMethod('rejectCall');
    } catch (e) {
      debugPrint('Error declining call: $e');
    }
  }

  Future<void> hangupCall() async {
    try {
      await _methodChannel.invokeMethod('disconnectCall');
    } catch (e) {
      debugPrint('Error hanging up: $e');
    }
  }

  Future<void> setMute(bool muted) async {
    try {
      await _methodChannel.invokeMethod('setMute', {'muted': muted});
    } catch (e) {
      debugPrint('Error setting mute: $e');
    }
  }

  Future<void> useSpeaker() async {
    try {
      await _methodChannel.invokeMethod('setAudioRoute', {'route': 'SPEAKER'});
    } catch (e) {
      debugPrint('Error using speaker: $e');
    }
  }

  Future<void> useEarpiece() async {
    try {
      await _methodChannel.invokeMethod('setAudioRoute', {'route': 'EARPIECE'});
    } catch (e) {
      debugPrint('Error using earpiece: $e');
    }
  }

  Future<void> useBluetooth() async {
    try {
      await _methodChannel.invokeMethod('setAudioRoute', {'route': 'BLUETOOTH'});
    } catch (e) {
      debugPrint('Error using bluetooth: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
