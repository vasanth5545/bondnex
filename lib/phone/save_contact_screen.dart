// File: lib/phone/save_contact_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../providers/contacts_provider.dart';

class SaveContactScreen extends StatefulWidget {
  final fc.Contact? contact; // Use the flutter_contacts model

  const SaveContactScreen({super.key, this.contact});

  @override
  State<SaveContactScreen> createState() => _SaveContactScreenState();
}

class _SaveContactScreenState extends State<SaveContactScreen> {
  bool _showMore = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _organizationController = TextEditingController();

  bool get _isEditMode => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Populate fields if editing an existing contact
      _firstNameController.text = widget.contact!.name.first;
      _lastNameController.text = widget.contact!.name.last;
      _phoneController.text = widget.contact!.phones.isNotEmpty ? widget.contact!.phones.first.number : '';
      _emailController.text = widget.contact!.emails.isNotEmpty ? widget.contact!.emails.first.address : '';
      _addressController.text = widget.contact!.addresses.isNotEmpty ? widget.contact!.addresses.first.address : '';
      _notesController.text = widget.contact!.notes.isNotEmpty ? widget.contact!.notes.first.note : '';
      _organizationController.text = widget.contact!.organizations.isNotEmpty ? widget.contact!.organizations.first.company : '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_firstNameController.text.isEmpty || _phoneController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('First name and phone number are required.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200));

    final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
    
    final contactToSave = _isEditMode ? widget.contact! : fc.Contact();

    contactToSave.name.first = _firstNameController.text.trim();
    contactToSave.name.last = _lastNameController.text.trim();
    
    if (contactToSave.phones.isNotEmpty) {
      contactToSave.phones.first.number = _phoneController.text.trim();
    } else {
      contactToSave.phones.add(fc.Phone(_phoneController.text.trim()));
    }

    // Update other fields...
    if (_emailController.text.isNotEmpty) {
      if (contactToSave.emails.isNotEmpty) {
        contactToSave.emails.first.address = _emailController.text.trim();
      } else {
        contactToSave.emails.add(fc.Email(_emailController.text.trim()));
      }
    }
    
    if (_addressController.text.isNotEmpty) {
       if (contactToSave.addresses.isNotEmpty) {
        contactToSave.addresses.first.address = _addressController.text.trim();
      } else {
        contactToSave.addresses.add(fc.Address(_addressController.text.trim()));
      }
    }

    if (_notesController.text.isNotEmpty) {
       if (contactToSave.notes.isNotEmpty) {
        contactToSave.notes.first.note = _notesController.text.trim();
      } else {
        contactToSave.notes.add(fc.Note(_notesController.text.trim()));
      }
    }
     if (_organizationController.text.isNotEmpty) {
       if (contactToSave.organizations.isNotEmpty) {
        contactToSave.organizations.first.company = _organizationController.text.trim();
      } else {
        contactToSave.organizations.add(fc.Organization(company: _organizationController.text.trim()));
      }
    }

    if (_isEditMode) {
      await contactsProvider.updateContact(contactToSave);
    } else {
      await contactsProvider.addContact(contactToSave);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEditMode ? 'Edit contact' : 'Create contact'),
        actions: [
          TextButton(
            onPressed: _saveContact,
            child: Text(_isEditMode ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color.fromARGB(255, 41, 40, 40),
              child: Icon(Icons.add_a_photo, size: 40, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _buildTextField('First name', _firstNameController),
            const SizedBox(height: 16),
            _buildTextField('Last name', _lastNameController),
            const SizedBox(height: 16),
            _buildTextField('Phone', _phoneController),
            const SizedBox(height: 24),
            
            if (_showMore)
              Column(
                children: [
                  _buildTextField('Email', _emailController),
                  const SizedBox(height: 16),
                  _buildTextField('Address', _addressController),
                  const SizedBox(height: 16),
                  _buildTextField('Notes', _notesController),
                  const SizedBox(height: 16),
                  _buildTextField('Organization', _organizationController),
                  const SizedBox(height: 16),
                ],
              ),

            TextButton(
              onPressed: () {
                setState(() {
                  _showMore = !_showMore;
                });
              },
              child: Text(_showMore ? 'See Less' : 'See More'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
