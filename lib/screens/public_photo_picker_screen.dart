// File: lib/public_photo_picker_screen.dart
// FINAL VERSION: Shows a proper permission request screen with an "Open Settings" button if denied.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PublicPhotoPickerScreen extends StatefulWidget {
  const PublicPhotoPickerScreen({super.key});

  @override
  State<PublicPhotoPickerScreen> createState() => _PublicPhotoPickerScreenState();
}

class _PublicPhotoPickerScreenState extends State<PublicPhotoPickerScreen> {
  List<AssetEntity> _allPhotos = [];
  List<AssetEntity> _selectedPhotos = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchPublicImages();
  }

  Future<void> _fetchPublicImages() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _permissionDenied = false; });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (paths.isNotEmpty) {
        final List<AssetEntity> assets = await paths.first.getAssetListPaged(page: 0, size: 1000);
        if (mounted) {
          setState(() {
            _allPhotos = assets;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
      }
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedPhotos.contains(asset)) {
        _selectedPhotos.remove(asset);
      } else {
        _selectedPhotos.add(asset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_selectedPhotos.isEmpty
                ? 'Select Photos'
                : '${_selectedPhotos.length} selected'),
        actions: [
          if (_selectedPhotos.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedPhotos);
              },
              child: const Text('Add', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 80, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'To select photos, please grant storage permission in your device settings.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                onPressed: () async {
                  await openAppSettings();
                  _fetchPublicImages();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: _allPhotos.length,
      itemBuilder: (context, index) {
        final asset = _allPhotos[index];
        final isSelected = _selectedPhotos.contains(asset);
        return GestureDetector(
          onTap: () => _toggleSelection(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: AssetEntityImage(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(250),
                  fit: BoxFit.cover,
                ),
              ),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blueAccent, width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.blueAccent, size: 30),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
