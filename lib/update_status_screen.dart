// File: lib/update_status_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({super.key});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  late TextEditingController _statusController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _statusController = TextEditingController(text: userProvider.status ?? "What's new?");
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _onShare() async {
    if (_statusController.text.trim().isEmpty) {
      return; // Onnum type pannalana onnum seiyathu
    }
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.updateUserStatus(_statusController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing status: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    ImageProvider? profileImageProvider;
    if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(userProvider.profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white70)
                        : null,
                  ),
                  Positioned(
                    top: -40,
                    child: _buildStatusBubble(context, _statusController.text),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(Icons.music_note, color: Colors.white),
              const Spacer(),
              TextField(
                controller: _statusController,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 22),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    // Bubble la text ah update panna
                  });
                },
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share with friends',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _onShare,
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBubble(BuildContext context, String text) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
        ),
        Positioned(
          bottom: -5,
          left: 20,
          child: Transform.rotate(
            angle: 45 * 3.14159 / 180,
            child: Container(
              width: 10,
              height: 10,
              color: const Color(0xFF2C2C2E),
            ),
          ),
        )
      ],
    );
  }
}
