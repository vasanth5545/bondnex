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

  // **THE FIX IS HERE**: Removed the fetchContacts() call from the constructor.
  // The contacts will now be fetched only when the contacts page is opened.
  ContactsProvider();

  Future<void> fetchContacts() async {
    // Prevent multiple fetches at the same time
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (await FlutterContacts.requestPermission()) {
        _permissionDenied = false;
        // This is the heavy operation that was blocking the app startup
        _contacts = await FlutterContacts.getContacts(withProperties: true);
      } else {
        _permissionDenied = true;
        _contacts = []; // Clear contacts if permission is denied
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
