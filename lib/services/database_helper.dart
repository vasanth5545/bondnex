// File: lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../phone/call_log_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    if (_database != null) {
      return _database!;
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bondnex.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
  }

  Future<void> insertCallLog(CallLogEntry log) async {
    final db = await database;
    await db.insert('call_logs', log.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final List<Map<String, dynamic>> maps = await db.query('call_logs', where: 'isSynced = 0');
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
}
