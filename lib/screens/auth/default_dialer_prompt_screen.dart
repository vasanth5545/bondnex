import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/telephony/call_manager_service.dart';
import 'auth_wrapper.dart';

class DefaultDialerPromptScreen extends StatefulWidget {
  const DefaultDialerPromptScreen({super.key});

  @override
  State<DefaultDialerPromptScreen> createState() => _DefaultDialerPromptScreenState();
}

class _DefaultDialerPromptScreenState extends State<DefaultDialerPromptScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIfDefaultAndProceed();
    }
  }

  Future<void> _checkIfDefaultAndProceed() async {
    if (_isChecking) return;
    _isChecking = true;
    final isDefault = await CallManagerService().isDefaultDialer();
    _isChecking = false;

    if (isDefault && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  Future<void> _requestDefault() async {
    await CallManagerService().requestDefaultDialer();
    // In Android < Q, it might start an intent. In Q+ it starts RoleManager intent.
    // We wait for the user to return to the app, which triggers didChangeAppLifecycleState.
    // However, just in case they accept very fast or it's a dialog that doesn't trigger pause/resume,
    // we can also start a timer or check immediately.
    Future.delayed(const Duration(seconds: 2), () {
      _checkIfDefaultAndProceed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background as requested
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop(); // Exit app
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Texts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use System\nPhone',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'More features, smarter experience',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center Graphic Representation
            Center(
              child: _buildGraphic(),
            ),

            const Spacer(),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _requestDefault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[400],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Set as default calling app',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphic() {
    return SizedBox(
      height: 300,
      width: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Phone
          Container(
            width: 150,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF2C303A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[800]!, width: 2),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Dialpad mock lines
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) => Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ),
                const Spacer(),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent[400]?.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Floating Card 1 (Green Call)
          Positioned(
            top: 40,
            right: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.greenAccent[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.call_received, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Container(width: 40, height: 6, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 16, color: Colors.green),
                  )
                ],
              ),
            ),
          ),

          // Floating Card 2 (Yellow Notes)
          Positioned(
            left: -20,
            top: 100,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2, color: Colors.white, size: 16),
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 4),
                  Container(width: 20, height: 4, color: Colors.white.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),

          // Floating Card 3 (Pink Recording)
          Positioned(
            right: 0,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.voicemail, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Container(width: 50, height: 4, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  const Icon(Icons.pause_circle_filled, color: Colors.white, size: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
