// File: lib/phone/widgets/swipeable_contact_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../../providers/display_settings_provider.dart';
import '../outgoing_call_screen.dart';
import '../contact_profile_screen.dart';
import '../message_screen.dart';

class SwipeableContactTile extends StatefulWidget {
  final fc.Contact contact;
  const SwipeableContactTile({super.key, required this.contact});

  @override
  State<SwipeableContactTile> createState() => _SwipeableContactTileState();
}

class _SwipeableContactTileState extends State<SwipeableContactTile> {
  double _opacity = 1.0;
  
  String _formatContactName(fc.Contact contact, NameSortOrder sortOrder) {
    if (contact.displayName.isEmpty) {
      return contact.phones.isNotEmpty ? contact.phones.first.number : 'Unknown';
    }
    if (sortOrder == NameSortOrder.lastNameFirst) {
      return '${contact.name.last} ${contact.name.first}'.trim();
    }
    return contact.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DisplaySettingsProvider>(
      builder: (context, displaySettings, child) {
        return Dismissible(
          key: ValueKey(widget.contact.id),
          background: _buildSwipeAction(Alignment.centerLeft, Colors.green, Icons.call),
          secondaryBackground: _buildSwipeAction(Alignment.centerRight, Colors.blue, Icons.message),
          onUpdate: (details) {
            final newOpacity = 1.0 - details.progress;
            if ((_opacity - newOpacity).abs() > 0.01) {
              setState(() {
                _opacity = newOpacity.clamp(0.0, 1.0);
              });
            }
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OutgoingCallScreen(
                    contact: widget.contact,
                    callType: 'SIM',
                  ),
                ),
              );
            } else if (direction == DismissDirection.endToStart) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessageScreen()),
              );
            }
            setState(() {
              _opacity = 1.0;
            });
            return false; // prevent actual delete
          },
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 80),
            curve: Curves.linear,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minVerticalPadding: 0,
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactDetailsScreen(
                          contact: widget.contact,
                        ),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person, size: 20),
                  ),
                ),
                title: Text(
                  _formatContactName(widget.contact, displaySettings.sortOrder),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  widget.contact.phones.isNotEmpty ? widget.contact.phones.first.number : 'No number',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OutgoingCallScreen(
                        contact: widget.contact,
                        callType: 'SIM',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeAction(AlignmentGeometry alignment, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
