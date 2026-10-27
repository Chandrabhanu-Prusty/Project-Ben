import 'package:sqflite/sqflite.dart';
import '../../core/utils/retention_policy.dart';
import '../models/chat_message.dart';
import 'app_database.dart';

class MessageDao {
  final AppDatabase _dbProvider;

  MessageDao({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  /// Inserts a new chat message.
  Future<void> insertMessage(ChatMessage message) async {
    final db = await _db;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves non-expired messages for a conversation, ordered chronologically.
  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    required String ownerUserId,
  }) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final results = await db.query(
      'messages',
      where: 'conversation_id = ? AND owner_user_id = ? AND expires_at > ?',
      whereArgs: [conversationId, ownerUserId, now],
      orderBy: 'created_at ASC',
    );

    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  /// Deletes a specific message.
  Future<void> deleteMessage(String id, String ownerUserId) async {
    final db = await _db;
    await db.delete(
      'messages',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Deletes all messages for a specific conversation.
  Future<void> deleteMessagesForConversation(
    String conversationId,
    String ownerUserId,
  ) async {
    final db = await _db;
    await db.delete(
      'messages',
      where: 'conversation_id = ? AND owner_user_id = ?',
      whereArgs: [conversationId, ownerUserId],
    );
  }
}
