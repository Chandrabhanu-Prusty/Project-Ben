import 'package:sqflite/sqflite.dart';
import '../../core/utils/retention_policy.dart';
import '../models/conversation.dart';
import 'app_database.dart';

class ConversationDao {
  final AppDatabase _dbProvider;

  ConversationDao({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  /// Inserts a new conversation.
  Future<void> insertConversation(Conversation conversation) async {
    final db = await _db;
    await db.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves non-expired conversations for the owner, ordered by latest update.
  Future<List<Conversation>> getConversations({
    required String ownerUserId,
    int? limit,
  }) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final results = await db.query(
      'conversations',
      where: 'owner_user_id = ? AND expires_at > ?',
      whereArgs: [ownerUserId, now],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return results.map((m) => Conversation.fromMap(m)).toList();
  }

  /// Gets a specific conversation by ID if not expired.
  Future<Conversation?> getConversationById(
    String id,
    String ownerUserId,
  ) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final results = await db.query(
      'conversations',
      where: 'id = ? AND owner_user_id = ? AND expires_at > ?',
      whereArgs: [id, ownerUserId, now],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Conversation.fromMap(results.first);
  }

  /// Updates conversation title.
  Future<void> updateTitle({
    required String id,
    required String ownerUserId,
    required String title,
  }) async {
    final db = await _db;
    await db.update(
      'conversations',
      {
        'title': title,
        'updated_at': RetentionPolicy.currentTimestamp(),
      },
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Touches updated_at timestamp without extending expires_at.
  Future<void> touchUpdatedAt({
    required String id,
    required String ownerUserId,
  }) async {
    final db = await _db;
    await db.update(
      'conversations',
      {
        'updated_at': RetentionPolicy.currentTimestamp(),
      },
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Deletes a conversation. Cascades to messages.
  Future<void> deleteConversation(String id, String ownerUserId) async {
    final db = await _db;
    await db.delete(
      'conversations',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Clears all conversations for the user.
  Future<void> clearAllForUser(String ownerUserId) async {
    final db = await _db;
    await db.delete(
      'conversations',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
    );
  }
}
