import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/utils/retention_policy.dart';

/// Database service managing the local SQLite database.
class AppDatabase {
  static const String _databaseName = 'ben_local.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  /// Singleton access or custom db injector for tests.
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );
  }

  /// Injects an in-memory or custom database for unit/integration testing.
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY NOT NULL,
        owner_user_id TEXT NOT NULL,
        app_name TEXT NOT NULL,
        package_name TEXT,
        source_key TEXT,
        sender_name TEXT,
        title TEXT,
        body TEXT,
        priority TEXT NOT NULL DEFAULT 'normal'
          CHECK (priority IN ('high', 'normal', 'low')),
        received_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        removed_at INTEGER,
        expires_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY NOT NULL,
        owner_user_id TEXT NOT NULL,
        title TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        UNIQUE (id, owner_user_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY NOT NULL,
        conversation_id TEXT NOT NULL,
        owner_user_id TEXT NOT NULL,
        role TEXT NOT NULL
          CHECK (role IN ('user', 'assistant')),
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id, owner_user_id)
          REFERENCES conversations (id, owner_user_id)
          ON DELETE CASCADE
      );
    ''');

    // Create Indexes
    await db.execute('''
      CREATE INDEX idx_notifications_owner_received
      ON notifications (owner_user_id, received_at DESC);
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_owner_expiry
      ON notifications (owner_user_id, expires_at);
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_owner_priority
      ON notifications (owner_user_id, priority, received_at DESC);
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_owner_package
      ON notifications (owner_user_id, package_name, received_at DESC);
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_notifications_source_key
      ON notifications (owner_user_id, source_key)
      WHERE source_key IS NOT NULL;
    ''');

    await db.execute('''
      CREATE INDEX idx_conversations_owner_updated
      ON conversations (owner_user_id, updated_at DESC);
    ''');

    await db.execute('''
      CREATE INDEX idx_conversations_owner_expiry
      ON conversations (owner_user_id, expires_at);
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_conversation_created
      ON messages (conversation_id, created_at ASC);
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_owner_expiry
      ON messages (owner_user_id, expires_at);
    ''');
  }

  /// Physical cleanup of expired records across all tables based on 36h retention.
  Future<int> cleanupExpiredRecords() async {
    final db = await database;
    final now = RetentionPolicy.currentExpiryCutoff();

    return await db.transaction((txn) async {
      final notifCount = await txn.delete(
        'notifications',
        where: 'expires_at <= ?',
        whereArgs: [now],
      );

      final convCount = await txn.delete(
        'conversations',
        where: 'expires_at <= ?',
        whereArgs: [now],
      );

      final msgCount = await txn.delete(
        'messages',
        where: 'expires_at <= ?',
        whereArgs: [now],
      );

      return notifCount + convCount + msgCount;
    });
  }

  /// Strictest privacy policy: deletes all data for a specific user upon logout.
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'notifications',
        where: 'owner_user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'conversations',
        where: 'owner_user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'messages',
        where: 'owner_user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
