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

  DateTime? _lastFetchTime;

  Future<void> fetchContacts({bool force = false}) async {
    if (_isLoading) return;

    final now = DateTime.now();
    if (!force &&
        _contacts.isNotEmpty &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < 15) {
      return; // Throttling: Skip if fetched less than 15 seconds ago
    }

    // Only show loading spinner if we don't have contacts yet
    final isBackgroundUpdate = _contacts.isNotEmpty;
    if (!isBackgroundUpdate) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (await FlutterContacts.requestPermission()) {
        _permissionDenied = false;
        // Fetch contacts without thumbnails for speed
        final newContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: true,
        );
        _contacts = newContacts;
        _lastFetchTime = DateTime.now();
      } else {
        _permissionDenied = true;
        _contacts = [];
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
      _permissionDenied = true;
      if (!isBackgroundUpdate) {
        _contacts = [];
      }
    } finally {
      if (!isBackgroundUpdate) {
        _isLoading = false;
      }
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
