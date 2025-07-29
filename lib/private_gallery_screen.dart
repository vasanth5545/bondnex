// File: lib/private_gallery_screen.dart
// VILAKKAM: Intha file-la, files add aanatha illaya enbathai sariyaaga
// dashboard screen-ku solgira logic serkapattullathu.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class PrivateGalleryScreen extends StatefulWidget {
  const PrivateGalleryScreen({super.key});

  @override
  State<PrivateGalleryScreen> createState() => _PrivateGalleryScreenState();
}

class _PrivateGalleryScreenState extends State<PrivateGalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<File> _photos = [];
  List<File> _videos = [];
  List<File> _audios = [];
  List<File> _documents = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLocalFiles();
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalFiles() async {
    setState(() => _isLoading = true);
    final appDir = await getApplicationDocumentsDirectory();
    
    _photos = await _getFilesFromDirectory(Directory('${appDir.path}/private/photos'));
    _videos = await _getFilesFromDirectory(Directory('${appDir.path}/private/videos'));
    _audios = await _getFilesFromDirectory(Directory('${appDir.path}/private/audios'));
    _documents = await _getFilesFromDirectory(Directory('${appDir.path}/private/documents'));

    setState(() => _isLoading = false);
  }

  Future<List<File>> _getFilesFromDirectory(Directory dir) async {
    if (await dir.exists()) {
      final files = await dir.list().toList();
      return files.whereType<File>().toList();
    }
    return [];
  }

  Future<void> _pickAndSaveFiles() async {
    bool filesWereAdded = false;
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.files.isEmpty) {
        // User entha file-um select pannala
        return;
      };

      filesWereAdded = true; // User files select pannitaanga
      final appDir = await getApplicationDocumentsDirectory();

      for (final file in result.files) {
        if (file.path == null) continue;
        
        final sourceFile = File(file.path!);
        String fileType = p.extension(file.path!).toLowerCase();
        String targetDir;

        if (['.jpg', '.jpeg', '.png', '.gif'].contains(fileType)) {
          targetDir = 'photos';
        } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(fileType)) {
          targetDir = 'videos';
        } else if (['.mp3', '.wav', '.m4a'].contains(fileType)) {
          targetDir = 'audios';
        } else {
          targetDir = 'documents';
        }

        final destinationDir = Directory('${appDir.path}/private/$targetDir');
        if (!await destinationDir.exists()) {
          await destinationDir.create(recursive: true);
        }

        final newPath = p.join(destinationDir.path, p.basename(file.path!));
        await sourceFile.copy(newPath);
      }

      await _loadLocalFiles();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: ${e.toString()}'))
        );
      }
    } finally {
      // Intha screen-ah close seiyum bodhu, files add aanatha illaya-nu solrom
      if (mounted) {
        Navigator.pop(context, filesWereAdded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Private Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo), text: 'Photos'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Audio'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSaveFiles,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFileGrid(_photos, isVideo: false),
                _buildFileGrid(_videos, isVideo: true),
                _buildFileList(_audios),
                _buildFileList(_documents),
              ],
            ),
    );
  }

  Widget _buildFileGrid(List<File> files, {required bool isVideo}) {
    if (files.isEmpty) {
      return Center(child: Text('No files found. Tap + to add.', style: TextStyle(color: Colors.grey[400])));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GridTile(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(file, fit: BoxFit.cover),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileList(List<File> files) {
    if (files.isEmpty) {
      return Center(child: Text('No files found. Tap + to add.', style: TextStyle(color: Colors.grey[400])));
    }
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file, color: Colors.white),
          title: Text(
            p.basename(file.path),
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
