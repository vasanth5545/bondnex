// File: lib/phone_screen.dart
// UPDATED: Dialpad layout-la iruntha empty space pirachanai sari seiyapattadhu.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class Contact {
  final String name;
  final String number;
  final String imageUrl;

  const Contact({required this.name, required this.number, required this.imageUrl});
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final List<Contact> suggestedContacts = [
    const Contact(name: 'Sophia Carter', number: 'Mobile 123-456-7890', imageUrl: 'https://via.placeholder.com/100/4A5C6A/FFFFFF?text=S'),
    const Contact(name: 'Ethan Bennett', number: 'Mobile 987-654-3210', imageUrl: 'https://via.placeholder.com/100/4A5C6A/FFFFFF?text=E'),
    const Contact(name: 'Olivia Hayes', number: 'Mobile 555-123-4567', imageUrl: 'https://via.placeholder.com/100/4A5C6A/FFFFFF?text=O'),
  ];

  final List<Contact> recentContacts = [
    const Contact(name: 'Sophia Carter', number: 'Mobile 123-456-7890', imageUrl: 'https://via.placeholder.com/100/4A5C6A/FFFFFF?text=S'),
    const Contact(name: 'Ethan Bennett', number: 'Mobile 987-654-3210', imageUrl: 'https://via.placeholder.com/100/4A5C6A/FFFFFF?text=E'),
  ];
  
  void _showDialpad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => DialpadSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.cogOutline),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDialpad,
        heroTag: 'phoneFAB',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(MdiIcons.dialpad),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildSectionHeader('Suggested'),
            ...suggestedContacts.map((contact) => _buildContactTile(contact)),
            const SizedBox(height: 24),
            _buildSectionHeader('Recent'),
            ...recentContacts.map((contact) => _buildContactTile(contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search contacts',
        prefixIcon: Icon(MdiIcons.magnify),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(contact.imageUrl),
      ),
      title: Text(contact.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(contact.number, style: GoogleFonts.poppins(color: Colors.grey[400])),
      onTap: () {
        // TODO: Call logic
      },
    );
  }
}

class DialpadSheet extends StatefulWidget {
  @override
  _DialpadSheetState createState() => _DialpadSheetState();
}

class _DialpadSheetState extends State<DialpadSheet> {
  final TextEditingController _controller = TextEditingController();

  void _onButtonPressed(String value) {
    setState(() {
      _controller.text += value;
    });
  }

  void _onBackspacePressed() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text =
            _controller.text.substring(0, _controller.text.length - 1);
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1))
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Visibility(
              visible: _controller.text.isNotEmpty,
              maintainAnimation: true,
              maintainState: true,
              child: Container(
                height: 80,
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _controller.text,
                          style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.backspace_outlined, color: Colors.grey[400]),
                      onPressed: _onBackspacePressed,
                      onLongPress: () {
                        setState(() {
                          _controller.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // **THE FIX IS HERE**: Spacer widget ippo sariyaana idathula irukku.
            const Spacer(),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ..._getDialButtons(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(child: _buildCallButton('sim', Colors.green, Icons.phone)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildCallButton('VOIP', Colors.purple, Icons.wifi_calling)),
                ],
              ),
            ),
             Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.contacts, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getDialButtons() {
    const numbers = [
      {'number': '1', 'letters': 'QZ'},
      {'number': '2', 'letters': 'ABC'},
      {'number': '3', 'letters': 'DEF'},
      {'number': '4', 'letters': 'GHI'},
      {'number': '5', 'letters': 'JKL'},
      {'number': '6', 'letters': 'MNO'},
      {'number': '7', 'letters': 'PQRS'},
      {'number': '8', 'letters': 'TUV'},
      {'number': '9', 'letters': 'WXYZ'},
      {'number': '*', 'letters': ''},
      {'number': '0', 'letters': '+'},
      {'number': '#', 'letters': ''},
    ];
    return numbers.map((e) => _buildDialButton(e['number']!, e['letters']!)).toList();
  }

  Widget _buildDialButton(String mainText, String subText) {
    return InkWell(
      onTap: () => _onButtonPressed(mainText),
      onLongPress: mainText == '0' ? () => _onButtonPressed('+') : null,
      borderRadius: BorderRadius.circular(100),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mainText,
              style:
                  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w400),
            ),
            if (subText.isNotEmpty)
              Text(
                subText,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(String label, Color color, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement SIM or VOIP call logic
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label.toUpperCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
