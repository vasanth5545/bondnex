// File: lib/phone/call_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

enum CallType { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
  final fc.Contact contact;
  final CallType type;
  final DateTime timestamp;
  final Duration duration;
  final bool isSynced;
  final bool isDeleted; // New flag for deletion status

  CallLogEntry({
    required this.id,
    required this.contact,
    required this.type,
    required this.timestamp,
    required this.duration,
    this.isSynced = false,
    this.isDeleted = false,
  });

  // Factory for creating from Firestore
  factory CallLogEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CallLogEntry(
      id: doc.id,
      contact: fc.Contact(
        displayName: data['contactName'] ?? 'Unknown',
        phones: [fc.Phone(data['contactNumber'] ?? '')]
      ),
      type: CallType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => CallType.missed,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      duration: Duration(seconds: data['duration'] ?? 0),
      isSynced: true,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // Factory for creating from local DB map
   factory CallLogEntry.fromDbMap(Map<String, dynamic> map) {
    return CallLogEntry(
      id: map['id'].toString(),
      contact: fc.Contact(
        displayName: map['contactName'],
        phones: [fc.Phone(map['contactNumber'])]
      ),
      type: CallType.values[map['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      duration: Duration(seconds: map['duration']),
      isSynced: map['isSynced'] == 1,
      isDeleted: map['isDeleted'] == 1,
    );
  }

  // Method to convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'contactName': contact.displayName,
      'contactNumber': contact.phones.isNotEmpty ? contact.phones.first.number : '',
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'duration': duration.inSeconds,
      'isDeleted': isDeleted,
    };
  }

  // Method to convert to a map for local DB
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'contactName': contact.displayName,
      'contactNumber': contact.phones.isNotEmpty ? contact.phones.first.number : '',
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inSeconds,
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }
}
