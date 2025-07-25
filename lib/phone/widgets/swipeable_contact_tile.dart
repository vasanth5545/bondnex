// File: lib/phone/widgets/swipeable_contact_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../../providers/display_settings_provider.dart';
import '../outgoing_call_screen.dart';
import '../contact_profile_screen.dart';
import '../message_screen.dart';

// MODIFIED: Intha function ippo ore oru color mattum tharum. Gradient illa.
Color _getColorForContact(String name) {
  final List<MaterialColor> materialColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen,
    Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown,
    Colors.blueGrey
  ];
  if (name.isEmpty) return Colors.grey;
  // Peroda hash code vechi, list-la irundhu oru color-ah select pannum.
  final int hashCode = name.hashCode;
  return materialColors[hashCode % materialColors.length];
}


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
        final displayName = _formatContactName(widget.contact, displaySettings.sortOrder);
        // MODIFIED: Ippo inga ore oru color thaan varum.
        final avatarColor = _getColorForContact(displayName);
        final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '#';

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
            return false;
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
                  // MODIFIED: CircleAvatar ippo gradient illama, ore color-la irukkum.
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    backgroundImage: widget.contact.photo != null ? MemoryImage(widget.contact.photo!) : null,
                    child: (widget.contact.photo == null)
                        ? Text(avatarLetter, style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                ),
                title: Text(
                  displayName,
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
