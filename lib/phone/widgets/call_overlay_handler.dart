import 'package:flutter/material.dart';
import 'package:bondnex/services/telephony/call_manager_service.dart';
import 'package:bondnex/phone/calls/incoming_call_screen.dart';
import 'package:bondnex/phone/calls/ongoing_call_screen.dart';

class CallOverlayHandler extends StatefulWidget {
  final Widget child;

  const CallOverlayHandler({super.key, required this.child});

  @override
  State<CallOverlayHandler> createState() => _CallOverlayHandlerState();
}

class _CallOverlayHandlerState extends State<CallOverlayHandler> {
  NativeCall? _currentCall;

  @override
  void initState() {
    super.initState();
    CallManagerService().init();
    CallManagerService().addListener(_onCallStateChanged);
  }

  @override
  void dispose() {
    CallManagerService().removeListener(_onCallStateChanged);
    super.dispose();
  }

  void _onCallStateChanged() {
    setState(() {
      _currentCall = CallManagerService().currentCall;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentCall != null)
          Positioned.fill(
            child: _buildCallScreen(_currentCall!),
          ),
      ],
    );
  }

  Widget _buildCallScreen(NativeCall call) {
    if (call.state == CallState.ringing) {
      return IncomingCallScreen(call: call);
    } else {
      return OngoingCallScreen(call: call);
    }
  }
}
