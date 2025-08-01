// File: lib/private_gallery_screen.dart
// UPDATED: Replaced the custom photo_manager picker with the simpler, native image_picker.
// This resolves the permission issues and provides a more familiar user experience.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart'; // Puthu package
import 'package:path/path.dart' as p;
import 'photo_view_screen.dart'; // Ithu theva padum

class PrivateGalleryScreen extends StatefulWidget {
  const PrivateGalleryScreen({super.key});

  @override
  State<PrivateGalleryScreen> createState() => _PrivateGalleryScreenState();
}

class _PrivateGalleryScreenState extends State<PrivateGalleryScreen> {
  List<File> _privateImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrivateImages();
  }

  Future<void> _fetchPrivateImages() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final privateFolderPath = '${directory.path}/private_gallery';
      final privateFolder = Directory(privateFolderPath);

      if (await privateFolder.exists()) {
        final files = privateFolder.listSync().whereType<File>().toList();
        if (mounted) setState(() => _privateImages = files);
      } else {
        if (mounted) setState(() => _privateImages = []);
      }
    } catch (e) {
      debugPrint("Error fetching private images: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // --- ITHA MAATHIRUKKOM ---
  Future<void> _pickAndSaveImages() async {
    final picker = ImagePicker();
    // Phone oda native gallery la irundhu multiple photos ah select panrom
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles.isEmpty || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final privateFolderPath = '${directory.path}/private_gallery';
      final privateFolder = Directory(privateFolderPath);
      if (!await privateFolder.exists()) {
        await privateFolder.create(recursive: true);
      }

      int successCount = 0;
      for (var xFile in pickedFiles) {
        final sourceFile = File(xFile.path);
        final fileName = p.basename(xFile.path);
        final newPath = '$privateFolderPath/$fileName';
        await sourceFile.copy(newPath);
        successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount photos saved to private gallery!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save photos: $e')),
      );
    } finally {
      // Puthusa save panna photos ah kaatrathuku refresh panrom
      _fetchPrivateImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Private Gallery'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSaveImages, // Function ah maathirukkom
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_privateImages.isEmpty) {
      return Center(
        child: Text(
          'No private photos.\nClick the + button to add from gallery.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _privateImages.length,
      itemBuilder: (context, index) {
        final file = _privateImages[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PhotoViewScreen(imageFile: file)),
            );
            // PhotoViewScreen la irundhu photo delete aana, ingayum refresh panrom
            if (result == true) {
              _fetchPrivateImages();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
