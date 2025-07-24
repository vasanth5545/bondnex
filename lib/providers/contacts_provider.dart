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

  ContactsProvider() {
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    _isLoading = true;
    notifyListeners();

    if (await FlutterContacts.requestPermission()) {
      _permissionDenied = false;
      _contacts = await FlutterContacts.getContacts(withProperties: true);
    } else {
      _permissionDenied = true;
    }
    _isLoading = false;
    notifyListeners();
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
