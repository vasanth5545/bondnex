// File: lib/phone/widgets/call_log_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/call_log_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../call_log_model.dart';
import '../outgoing_call_screen.dart';
import '../call_log_details_screen.dart';
import '../contact_profile_screen.dart';
import '../message_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

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

class CallLogTile extends StatelessWidget {
  final CallLogEntry log;
  const CallLogTile({super.key, required this.log});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDay == today) {
      return DateFormat.jm().format(timestamp);
    } else if (logDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMd().format(timestamp);
    }
  }

  String _formatContactName(fc.Contact contact, NameSortOrder sortOrder) {
    if (contact.displayName.isEmpty) {
      return contact.phones.isNotEmpty ? contact.phones.first.number : 'Unknown';
    }
    if (sortOrder == NameSortOrder.lastNameFirst) {
      return '${contact.name.last} ${contact.name.first}'.trim();
    }
    return contact.displayName;
  }

  void _makeCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutgoingCallScreen(
          contact: log.contact,
          callType: 'SIM',
        ),
      ),
    );
  }

  void _openMessages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessageScreen()),
    );
  }

  void _deleteLog(BuildContext context) {
    final callLogProvider = Provider.of<CallLogProvider>(context, listen: false);
    callLogProvider.deleteCallLog(log.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DisplaySettingsProvider>(
      builder: (context, displaySettings, child) {
        IconData icon;
        Color color;

        switch (log.type) {
          case CallType.incoming:
            icon = Icons.call_received;
            color = Colors.green;
            break;
          case CallType.outgoing:
            icon = Icons.call_made;
            color = Colors.blue;
            break;
          case CallType.missed:
            icon = Icons.call_missed;
            color = Colors.red;
            break;
        }

        final titleText = _formatContactName(log.contact, displaySettings.sortOrder);
        final subtitleText = log.contact.phones.isNotEmpty ? "+91 ${log.contact.phones.first.number}" : "No number";
        // MODIFIED: Ippo inga ore oru color thaan varum.
        final avatarColor = _getColorForContact(titleText);
        final avatarLetter = titleText.isNotEmpty ? titleText[0].toUpperCase() : '#';

        final listTile = ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailsScreen(contact: log.contact),
                ),
              );
            },
            // MODIFIED: CircleAvatar ippo gradient illama, ore color-la irukkum.
            child: CircleAvatar(
              backgroundColor: avatarColor,
              backgroundImage: log.contact.photo != null ? MemoryImage(log.contact.photo!) : null,
              child: (log.contact.photo == null)
                  ? Text(avatarLetter, style: const TextStyle(color: Colors.white))
                  : null,
            ),
          ),
          title: Text(
            titleText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: GoogleFonts.poppins(color: Colors.grey[400]),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(log.timestamp),
                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          onTap: () => _makeCall(context),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Log'),
                content: const Text('Are you sure you want to delete this call log? This action will be visible to your partner.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      _deleteLog(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        );

        return Dismissible(
          key: ValueKey(log.id),
          background: _buildSwipeAction(Alignment.centerLeft, Colors.green, Icons.call),
          secondaryBackground: _buildSwipeAction(Alignment.centerRight, Colors.blue, Icons.message),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _makeCall(context);
            } else if (direction == DismissDirection.endToStart) {
              _openMessages(context);
            }
            return false;
          },
          child: listTile,
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
