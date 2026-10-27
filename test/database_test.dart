import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ben/core/utils/retention_policy.dart';
import 'package:ben/data/local/app_database.dart';
import 'package:ben/data/models/notification_item.dart';
import 'package:ben/data/models/conversation.dart';
import 'package:ben/data/models/chat_message.dart';
import 'package:ben/data/repositories/notification_repository.dart';
import 'package:ben/data/repositories/conversation_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AppDatabase appDb;
  late NotificationRepository notifRepo;
  late ConversationRepository convRepo;

  setUp(() async {
    // Open in-memory database
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON;');

    appDb = AppDatabase.instance;
    appDb.setDatabaseForTesting(db);

    // Run schema creation
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

    notifRepo = NotificationRepository();
    convRepo = ConversationRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2 Database & Storage Layer Tests', () {
    test('Notification CRUD, grouping, and account isolation', () async {
      const userA = 'user_a';
      const userB = 'user_b';

      final notifA1 = NotificationItem.create(
        id: 'n1',
        ownerUserId: userA,
        appName: 'WhatsApp',
        senderName: 'Alice',
        title: 'Project deadline',
        body: 'Please review before tomorrow',
        priority: 'high',
      );

      final notifA2 = NotificationItem.create(
        id: 'n2',
        ownerUserId: userA,
        appName: 'Gmail',
        senderName: 'Prof. Davis',
        title: 'Assignment',
        body: 'Grades released',
        priority: 'normal',
      );

      final notifB1 = NotificationItem.create(
        id: 'n3',
        ownerUserId: userB,
        appName: 'Shopping',
        title: 'Package delivered',
        priority: 'low',
      );

      await notifRepo.saveNotification(notifA1);
      await notifRepo.saveNotification(notifA2);
      await notifRepo.saveNotification(notifB1);

      // Verify User A only sees User A's notifications
      final userANotifs = await notifRepo.getNotifications(ownerUserId: userA);
      expect(userANotifs.length, 2);
      expect(userANotifs.any((n) => n.id == 'n3'), isFalse);

      // Verify User B only sees User B's notifications
      final userBNotifs = await notifRepo.getNotifications(ownerUserId: userB);
      expect(userBNotifs.length, 1);
      expect(userBNotifs.first.appName, 'Shopping');

      // Verify counts and grouping
      final countA = await notifRepo.getNotificationCount(ownerUserId: userA);
      expect(countA, 2);

      final grouped = await notifRepo.getGroupedNotifications(ownerUserId: userA);
      expect(grouped.keys.length, 2);
      expect(grouped['WhatsApp']!.first.senderName, 'Alice');

      final highPriority = await notifRepo.getNotifications(
        ownerUserId: userA,
        priorityFilter: 'high',
      );
      expect(highPriority.length, 1);
      expect(highPriority.first.id, 'n1');
    });

    test('36-Hour Expiration filter excludes expired records', () async {
      const user = 'user_test';
      final now = RetentionPolicy.currentTimestamp();

      // Non-expired notification
      final activeNotif = NotificationItem(
        id: 'active_1',
        ownerUserId: user,
        appName: 'Slack',
        receivedAt: now,
        updatedAt: now,
        expiresAt: now + 100000,
      );

      // Already expired notification (received 37 hours ago)
      final expiredNotif = NotificationItem(
        id: 'expired_1',
        ownerUserId: user,
        appName: 'Email',
        receivedAt: now - (37 * 3600 * 1000),
        updatedAt: now - (37 * 3600 * 1000),
        expiresAt: now - (1 * 3600 * 1000),
      );

      await notifRepo.saveNotification(activeNotif);
      await notifRepo.saveNotification(expiredNotif);

      // Query should automatically exclude expired records
      final list = await notifRepo.getNotifications(ownerUserId: user);
      expect(list.length, 1);
      expect(list.first.id, 'active_1');

      // Physical cleanup should delete the expired record
      final cleanedCount = await appDb.cleanupExpiredRecords();
      expect(cleanedCount, 1);
    });

    test('Conversation and Message Cascade Deletion', () async {
      const user = 'user_chat';

      final conv = Conversation.create(
        id: 'conv_1',
        ownerUserId: user,
        title: 'Notification Summary Chat',
      );
      await convRepo.saveConversation(conv);

      final msg1 = ChatMessage.create(
        id: 'm1',
        conversationId: 'conv_1',
        ownerUserId: user,
        role: 'user',
        content: 'What did I miss?',
      );
      final msg2 = ChatMessage.create(
        id: 'm2',
        conversationId: 'conv_1',
        ownerUserId: user,
        role: 'assistant',
        content: 'You have 2 new notifications.',
      );

      await convRepo.addMessage(msg1);
      await convRepo.addMessage(msg2);

      final messages = await convRepo.getMessages(
        conversationId: 'conv_1',
        ownerUserId: user,
      );
      expect(messages.length, 2);
      expect(messages.first.role, 'user');
      expect(messages.last.role, 'assistant');

      // Deleting conversation cascades to messages
      await convRepo.deleteConversation('conv_1', user);

      final remainingConv = await convRepo.getConversationById('conv_1', user);
      expect(remainingConv, isNull);

      final remainingMsgs = await convRepo.getMessages(
        conversationId: 'conv_1',
        ownerUserId: user,
      );
      expect(remainingMsgs.isEmpty, isTrue);
    });

    test('User Logout cleans up all data (Strictest Privacy choice)', () async {
      const user = 'user_logout';

      final notif = NotificationItem.create(
        id: 'notif_logout',
        ownerUserId: user,
        appName: 'WhatsApp',
      );
      await notifRepo.saveNotification(notif);

      final conv = Conversation.create(
        id: 'conv_logout',
        ownerUserId: user,
        title: 'Session before logout',
      );
      await convRepo.saveConversation(conv);

      final msg = ChatMessage.create(
        id: 'msg_logout',
        conversationId: 'conv_logout',
        ownerUserId: user,
        role: 'user',
        content: 'Testing logout wipe',
      );
      await convRepo.addMessage(msg);

      // Perform logout cleanup
      await appDb.clearUserData(user);

      final notifsAfter = await notifRepo.getNotifications(ownerUserId: user);
      final convsAfter = await convRepo.getConversations(ownerUserId: user);

      expect(notifsAfter.isEmpty, isTrue);
      expect(convsAfter.isEmpty, isTrue);
    });
  });
}
