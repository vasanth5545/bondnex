// File: lib/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.contacts, Permission.phone, Permission.sms, Permission.camera,
      Permission.location, Permission.microphone, Permission.audio, Permission.notification,
    ];
    
    for (var permission in permissions) {
      _permissionStatus[permission] = await permission.isGranted;
    }
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    final permissionsToRequest = _permissionStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    for (var permission in permissionsToRequest) {
      final status = await permission.request();
      _permissionStatus[permission] = status.isGranted;
      setState(() {});
    }

    if (_permissionStatus.values.every((granted) => granted)) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some permissions were not granted. The app may not function correctly.')),
        );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_outlined, size: 80),
              const SizedBox(height: 24),
              Text(
                'Permissions Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'For the best experience, this app needs access to several features on your device. Please grant the following permissions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permissions'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings Manually'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
