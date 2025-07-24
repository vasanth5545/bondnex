// File: lib/settings/merge_contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../providers/contacts_provider.dart';

class MergeContactsScreen extends StatefulWidget {
  const MergeContactsScreen({super.key});

  @override
  State<MergeContactsScreen> createState() => _MergeContactsScreenState();
}

class _MergeContactsScreenState extends State<MergeContactsScreen> {
  Map<String, List<fc.Contact>> _duplicates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  void _findDuplicates() {
    final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
    final contacts = contactsProvider.contacts;
    final Map<String, List<fc.Contact>> potentialDuplicates = {};

    for (var contact in contacts) {
      // Group by display name (case-insensitive)
      final nameKey = contact.displayName.toLowerCase().trim();
      if (nameKey.isNotEmpty) {
        potentialDuplicates.putIfAbsent(nameKey, () => []).add(contact);
      }
      // Group by phone number
      for (var phone in contact.phones) {
        final phoneKey = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
        if (phoneKey.isNotEmpty) {
          potentialDuplicates.putIfAbsent(phoneKey, () => []).add(contact);
        }
      }
    }

    setState(() {
      _duplicates = Map.fromEntries(
        potentialDuplicates.entries.where((entry) => entry.value.length > 1)
      );
    });
  }

  Future<void> _merge(List<fc.Contact> contactsToMerge) async {
    // This is a simplified merge logic. A real-world app might need a more
    // sophisticated UI to let the user choose which data to keep.
    final primaryContact = contactsToMerge.first;
    for (int i = 1; i < contactsToMerge.length; i++) {
      final dupe = contactsToMerge[i];
      primaryContact.phones.addAll(dupe.phones);
      primaryContact.emails.addAll(dupe.emails);
      // ... merge other fields as needed
      await dupe.delete();
    }
    await primaryContact.update();
    _findDuplicates(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Duplicates'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _duplicates.isEmpty
              ? Center(
                  child: Text(
                    'No duplicates found.',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _duplicates.length,
                  itemBuilder: (context, index) {
                    final key = _duplicates.keys.elementAt(index);
                    final duplicateGroup = _duplicates[key]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text('Found ${duplicateGroup.length} duplicates for "${duplicateGroup.first.displayName}"'),
                        children: [
                          ...duplicateGroup.map((contact) => ListTile(
                            title: Text(contact.displayName),
                            subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No number'),
                          )),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () => _merge(duplicateGroup),
                              child: const Text('Merge'),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
