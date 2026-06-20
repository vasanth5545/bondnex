import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bondnex/services/telephony/call_manager_service.dart';

class OngoingCallScreen extends StatefulWidget {
  final NativeCall call;

  const OngoingCallScreen({super.key, required this.call});

  @override
  State<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.call.state == CallState.active) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(OngoingCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.call.state == CallState.active && oldWidget.call.state != CallState.active) {
      _startTimer();
    } else if (widget.call.state != CallState.active) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.call.number;
    final stateStr = widget.call.state.name;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            // Caller Info
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  callerName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.call.state == CallState.active 
                      ? _formatDuration(_secondsElapsed)
                      : stateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: widget.call.state == CallState.active 
                        ? Colors.white 
                        : Colors.white54,
                  ),
                ),
              ],
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlBtn(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: 'Mute',
                        isActive: _isMuted,
                        onTap: () {
                          setState(() {
                            _isMuted = !_isMuted;
                          });
                          CallManagerService().setMute(_isMuted);
                        },
                      ),
                      _buildControlBtn(
                        icon: Icons.dialpad,
                        label: 'Keypad',
                        isActive: false,
                        onTap: () {
                          // Implement in-call dialpad later
                        },
                      ),
                      _buildControlBtn(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        label: 'Speaker',
                        isActive: _isSpeakerOn,
                        onTap: () {
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                          });
                          if (_isSpeakerOn) {
                            CallManagerService().useSpeaker();
                          } else {
                            CallManagerService().useEarpiece();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Hang up
                  GestureDetector(
                    onTap: () {
                      CallManagerService().hangupCall();
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.grey[850],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
