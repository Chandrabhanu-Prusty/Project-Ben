import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/retention_policy.dart';
import '../data/models/notification_item.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/notification_bridge.dart';

class NotificationStateController extends ChangeNotifier {
  final NotificationRepository _repository;
  String? _currentUserId;

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationItem> _notifications = [];
  Map<String, List<NotificationItem>> _groupedNotifications = {};
  Map<String, int> _appCounts = {};

  StreamSubscription? _streamSub;

  NotificationStateController({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationItem> get notifications => _notifications;
  Map<String, List<NotificationItem>> get groupedNotifications => _groupedNotifications;
  Map<String, int> get appCounts => _appCounts;

  int get totalCount => _notifications.length;
  int get highPriorityCount => _notifications.where((n) => n.isHighPriority).length;

  List<NotificationItem> get highPriorityNotifications =>
      _notifications.where((n) => n.isHighPriority).toList();

  /// Sets the active authenticated user and begins listening.
  void setUserId(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    if (userId != null) {
      loadNotifications();
      _startStreamListener();
    } else {
      _streamSub?.cancel();
      _notifications = [];
      _groupedNotifications = {};
      _appCounts = {};
      notifyListeners();
    }
  }

  void _startStreamListener() {
    _streamSub?.cancel();
    _streamSub = NotificationBridge.incomingNotificationStream.listen((data) async {
      if (_currentUserId == null || data.isEmpty) return;

      final item = NotificationBridge.parseNotificationEvent(data, _currentUserId!);
      if (item != null) {
        // Classify priority with local heuristic rules
        final classifiedPriority = classifyLocalPriority(item.title, item.body);
        final finalItem = item.copyWith(priority: classifiedPriority);

        await _repository.saveNotification(finalItem);
        await loadNotifications(silent: true);
      }
    });
  }

  /// Refreshes all non-expired notifications for active user.
  Future<void> loadNotifications({bool silent = false}) async {
    if (_currentUserId == null) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _notifications = await _repository.getNotifications(ownerUserId: _currentUserId!);
      _groupedNotifications = await _repository.getGroupedNotifications(ownerUserId: _currentUserId!);
      _appCounts = await _repository.getCountsByApp(ownerUserId: _currentUserId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a notification manually (essential for iOS workflow or manual input).
  Future<void> addManualNotification({
    required String appName,
    String? title,
    String? body,
    String? senderName,
  }) async {
    if (_currentUserId == null) return;

    final classifiedPriority = classifyLocalPriority(title, body);
    final now = RetentionPolicy.currentTimestamp();

    final item = NotificationItem.create(
      id: 'manual_${now}_${appName.hashCode}',
      ownerUserId: _currentUserId!,
      appName: appName,
      senderName: senderName,
      title: title,
      body: body,
      priority: classifiedPriority,
      receivedAt: now,
    );

    await _repository.saveNotification(item);
    await loadNotifications(silent: true);
  }

  /// Local rule-based priority classifier as specified in the PRD and TRD.
  static String classifyLocalPriority(String? title, String? body) {
    final text = '${title ?? ''} ${body ?? ''}'.toLowerCase();

    // High Priority keywords (deadlines, urgent, security, payments)
    const highKeywords = [
      'deadline',
      'urgent',
      'asap',
      'due today',
      'expires today',
      'last date',
      'critical',
      'security alert',
      'bank alert',
      'otp',
      'fraud',
      'payment due',
      'overdue',
      'interview',
      'action required',
    ];

    for (final kw in highKeywords) {
      if (text.contains(kw)) {
        return 'high';
      }
    }

    // Low Priority keywords (promotions, ads, offers)
    const lowKeywords = [
      'discount',
      'coupon',
      'mega sale',
      'promo',
      'cashback',
      'flat 50%',
      'free shipping',
      'sponsored',
      'unmissable deal',
    ];

    for (final kw in lowKeywords) {
      if (text.contains(kw)) {
        return 'low';
      }
    }

    return 'normal';
  }

  Future<void> deleteNotification(String id) async {
    if (_currentUserId == null) return;
    await _repository.deleteNotification(id, _currentUserId!);
    await loadNotifications(silent: true);
  }

  Future<void> clearAll() async {
    if (_currentUserId == null) return;
    await _repository.clearAll(_currentUserId!);
    await loadNotifications(silent: true);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
