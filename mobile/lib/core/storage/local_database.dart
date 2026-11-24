import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabaseHelper {
  static Database? _database;
  static bool _hasInitFailed = false;
  static const String _dbName = 'soulm8_offline.db';
  static const int _dbVersion = 1;

  // In-memory fallback if native SQLite fails on certain platforms
  static final List<Map<String, dynamic>> _inMemoryAIMessages = [];

  static Future<Database?> get database async {
    if (_hasInitFailed) return null;
    if (_database != null) return _database;
    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      debugPrint('⚠️ LocalDatabaseHelper init failed, falling back to memory: $e');
      _hasInitFailed = true;
      return null;
    }
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite not directly used on web');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final docDir = await getApplicationDocumentsDirectory();
      final path = join(docDir.path, _dbName);
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _createTables,
        ),
      );
    } else {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
      );
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    // 1. Local Human Messages Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_human_messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        content TEXT NOT NULL,
        media_url TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 1
      )
    ''');

    // 2. Local AI Messages Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_ai_messages (
        id TEXT PRIMARY KEY,
        is_user INTEGER NOT NULL,
        content TEXT NOT NULL,
        active_mode TEXT NOT NULL,
        photo_url TEXT,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 1
      )
    ''');

    // 3. Local Cached Memories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_cached_memories (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        fact_key TEXT NOT NULL,
        fact_value TEXT NOT NULL,
        is_superseded INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // --- AI Offline Persistence ---
  static Future<void> insertAIMessage({
    required String id,
    required bool isUser,
    required String content,
    required String activeMode,
    String? photoUrl,
    required int createdAt,
  }) async {
    final entry = {
      'id': id,
      'is_user': isUser ? 1 : 0,
      'content': content,
      'active_mode': activeMode,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'synced': 1,
    };

    _inMemoryAIMessages.add(entry);

    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          'local_ai_messages',
          entry,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('⚠️ insertAIMessage SQLite error (safe): $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAIMessages() async {
    try {
      final db = await database;
      if (db != null) {
        final rows = await db.query(
          'local_ai_messages',
          orderBy: 'created_at ASC',
        );
        if (rows.isNotEmpty) return rows;
      }
    } catch (e) {
      debugPrint('⚠️ getAIMessages SQLite error (safe): $e');
    }
    return _inMemoryAIMessages;
  }

  static Future<void> wipeAllLocalData() async {
    _inMemoryAIMessages.clear();
    try {
      final db = await database;
      if (db != null) {
        await db.delete('local_human_messages');
        await db.delete('local_ai_messages');
        await db.delete('local_cached_memories');
      }
    } catch (_) {}
  }
}
