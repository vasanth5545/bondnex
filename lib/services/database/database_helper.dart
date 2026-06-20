// File: lib/services/database_helper.dart
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/call_log_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final _secureStorage = const FlutterSecureStorage();
  static const String _dbKeyStorageKey = 'bondnex_db_encryption_key';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<String> _getOrGenerateEncryptionKey() async {
    String? key = await _secureStorage.read(key: _dbKeyStorageKey);
    if (key == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(bytes);
      await _secureStorage.write(key: _dbKeyStorageKey, value: key);
    }
    return key;
  }

  Future<Database> initDatabase() async {
    if (_database != null) {
      return _database!;
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bondnex_secure.db'); // New db name to avoid crash on existing unencrypted db
    
    final dbKey = await _getOrGenerateEncryptionKey();

    _database = await openDatabase(
      path, 
      password: dbKey,
      version: 2, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE call_logs(
        id TEXT PRIMARY KEY,
        contactName TEXT,
        contactNumber TEXT,
        type INTEGER,
        timestamp INTEGER,
        duration INTEGER,
        isSynced INTEGER,
        isDeleted INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        chatId TEXT,
        senderId TEXT,
        receiverId TEXT,
        text TEXT,
        timestamp INTEGER,
        isRead INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE messages(
          id TEXT PRIMARY KEY,
          chatId TEXT,
          senderId TEXT,
          receiverId TEXT,
          text TEXT,
          timestamp INTEGER,
          isRead INTEGER
        )
      ''');
    }
  }

  Future<void> insertCallLog(CallLogEntry log) async {
    final db = await database;
    await db.insert(
      'call_logs',
      log.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CallLogEntry>> getCallLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'isDeleted = 0',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return CallLogEntry.fromDbMap(maps[i]);
    });
  }

  /// Fetches the single most recent call log from the database.
  Future<CallLogEntry?> getLatestCallLog() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CallLogEntry.fromDbMap(maps.first);
    }
    return null;
  }

  Future<List<CallLogEntry>> getUnsyncedCallLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      where: 'isSynced = 0',
    );
    return List.generate(maps.length, (i) {
      return CallLogEntry.fromDbMap(maps[i]);
    });
  }

  /// Fetches the top 10 most recent logs overall, regardless of sync/delete status, to upload as a single array to Firebase.
  Future<List<CallLogEntry>> getTop10LogsForSync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
      limit: 10,
    );
    return List.generate(maps.length, (i) {
      return CallLogEntry.fromDbMap(maps[i]);
    });
  }

  Future<void> markCallLogsAsSynced(List<String> ids) async {
    final db = await database;
    await db.update(
      'call_logs',
      {'isSynced': 1},
      where: 'id IN (${ids.map((_) => '?').join(', ')})',
      whereArgs: ids,
    );
  }

  Future<void> markAsDeleted(String logId) async {
    final db = await database;
    await db.update(
      'call_logs',
      {'isDeleted': 1, 'isSynced': 0}, // Mark as deleted and needing sync
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  // --- Messages Methods ---

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMessages(List<Map<String, dynamic>> messages) async {
    final db = await database;
    Batch batch = db.batch();
    for (var message in messages) {
      batch.insert(
        'messages',
        message,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMessagesForChat(String chatId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> getLastMessageTimestamp(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      columns: ['timestamp'],
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty && maps.first['timestamp'] != null) {
      return maps.first['timestamp'] as int;
    }
    return 0; // Return 0 if no messages exist
  }

  Future<void> deleteEntireDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bondnex_secure.db');
    await deleteDatabase(path);
  }
}
