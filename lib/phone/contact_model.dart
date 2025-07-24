// File: lib/phone/call_log_model.dart
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

enum CallType { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
  final fc.Contact contact;
  final CallType type;
  final DateTime timestamp;
  final Duration duration;

  CallLogEntry({
    required this.id,
    required this.contact,
    required this.type,
    required this.timestamp,
    required this.duration,
  });
}
