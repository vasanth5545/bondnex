// File: lib/providers/contacts_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  bool _permissionDenied = false;
  bool _isLoading = false;

  List<Contact> get contacts => _contacts;
  bool get permissionDenied => _permissionDenied;
  bool get isLoading => _isLoading;

  ContactsProvider();

  Future<void> fetchContacts() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (await FlutterContacts.requestPermission()) {
        _permissionDenied = false;
        // MODIFIED: Fetched contacts with photos and properties (like phone numbers)
        // This ensures all data is available immediately for the UI, fixing the delay.
        _contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );
      } else {
        _permissionDenied = true;
        _contacts = [];
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
      _permissionDenied = true;
      _contacts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(Contact newContact) async {
    await newContact.insert();
    await fetchContacts(); // Refresh the list from the device
  }

  Future<void> updateContact(Contact updatedContact) async {
    await updatedContact.update();
    await fetchContacts(); // Refresh the list from the device
  }
}
