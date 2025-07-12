// File: lib/settings/change_name_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  late TextEditingController _currentNameController;
  late TextEditingController _newNameController;

  @override
  void initState() {
    super.initState();
    // Get the current name from the provider when the screen loads
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentNameController = TextEditingController(text: userProvider.userName);
    _newNameController = TextEditingController();
  }

  @override
  void dispose() {
    _currentNameController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to rebuild the current name field when the name changes
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Update the controller text if it has changed in the provider
        if (_currentNameController.text != userProvider.userName) {
          _currentNameController.text = userProvider.userName;
        }
        
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Change Name'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Name',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentNameController,
                    readOnly: true,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'New Name',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newNameController,
                    decoration: const InputDecoration(
                      hintText: 'Type your new name here...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This name will be visible to your partner.',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            minimumSize: const Size(0, 50),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // **THE FIX IS HERE** - Update name using the provider
                            if (_newNameController.text.isNotEmpty) {
                              userProvider.updateUserName(_newNameController.text);
                              // Optionally, show a success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name updated successfully!')),
                              );
                              // Clear the new name field after saving
                              _newNameController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                             minimumSize: const Size(0, 50),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
