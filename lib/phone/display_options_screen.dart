// File: lib/phone/display_options_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/display_settings_provider.dart';

class DisplayOptionsScreen extends StatelessWidget {
  const DisplayOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DisplaySettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Display Options'),
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Name Sort Order'.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              RadioListTile<NameSortOrder>(
                title: const Text('First name, Last name'),
                subtitle: const Text('e.g., Kalai Sri'),
                value: NameSortOrder.firstNameFirst,
                groupValue: settings.sortOrder,
                onChanged: (value) {
                  if (value != null) {
                    settings.setSortOrder(value);
                  }
                },
              ),
              RadioListTile<NameSortOrder>(
                title: const Text('Last name, First name'),
                subtitle: const Text('e.g., Sri Kalai'),
                value: NameSortOrder.lastNameFirst,
                groupValue: settings.sortOrder,
                onChanged: (value) {
                  if (value != null) {
                    settings.setSortOrder(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
