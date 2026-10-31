import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_item.dart';
import '../../data/services/notification_bridge.dart';
import '../../state/notification_state.dart';
import '../../widgets/priority_badge.dart';
import 'notification_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _notificationAccessEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccess();
      context.read<NotificationStateController>().loadNotifications(silent: true);
    }
  }

  Future<void> _checkAccess() async {
    if (!kIsWeb && Platform.isAndroid) {
      final granted = await NotificationBridge.isNotificationAccessGranted();
      if (mounted) {
        setState(() => _notificationAccessEnabled = granted);
      }
    }
  }

  void _showManualAddDialog() {
    final appController = TextEditingController(text: 'WhatsApp');
    final senderController = TextEditingController();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestCharcoal,
        title: const Text('Add Test Notification', style: TextStyle(color: AppColors.softWhite)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: appController,
                style: const TextStyle(color: AppColors.softWhite),
                decoration: const InputDecoration(labelText: 'App Name (e.g. WhatsApp, Gmail)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: senderController,
                style: const TextStyle(color: AppColors.softWhite),
                decoration: const InputDecoration(labelText: 'Sender (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.softWhite),
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.softWhite),
                decoration: const InputDecoration(labelText: 'Message Body / Preview'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (appController.text.trim().isNotEmpty) {
                context.read<NotificationStateController>().addManualNotification(
                      appName: appController.text.trim(),
                      senderName: senderController.text.trim().isEmpty ? null : senderController.text.trim(),
                      title: titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                      body: bodyController.text.trim().isEmpty ? null : bodyController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifState = context.watch<NotificationStateController>();
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withAlpha(100),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/omnitrix_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('BEN'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add / Paste Notification',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonGreen),
            onPressed: _showManualAddDialog,
          ),
          IconButton(
            tooltip: 'Refresh Notifications',
            icon: const Icon(Icons.refresh, color: AppColors.softWhite),
            onPressed: () => notifState.loadNotifications(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          backgroundColor: AppColors.darkCharcoal,
          onRefresh: () => notifState.loadNotifications(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Notification access banner for Android if disabled
              if (isAndroid && !_notificationAccessEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.alertRed.withAlpha(120)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.alertRed),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notification access is disabled. Ben cannot capture alerts automatically.',
                          style: TextStyle(fontSize: 13, color: AppColors.softWhite),
                        ),
                      ),
                      TextButton(
                        onPressed: () => NotificationBridge.openNotificationSettings(),
                        child: const Text('Enable', style: TextStyle(color: AppColors.neonGreen)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Overview Summary Card
              _buildOverviewCard(notifState),

              const SizedBox(height: 20),

              // High Priority Section
              if (notifState.highPriorityNotifications.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.priority_high, size: 20, color: AppColors.alertRed),
                        const SizedBox(width: 6),
                        const Text(
                          'Needs Attention',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.softWhite,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${notifState.highPriorityCount} urgent',
                      style: const TextStyle(fontSize: 13, color: AppColors.alertRed),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...notifState.highPriorityNotifications.map(
                  (item) => _buildNotificationCard(item),
                ),
                const SizedBox(height: 24),
              ],

              // Grouped Notifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grouped by Application',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.softWhite,
                    ),
                  ),
                  Text(
                    '${notifState.totalCount} total',
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (notifState.notifications.isEmpty) ...[
                _buildEmptyState(isAndroid),
              ] else ...[
                ...notifState.groupedNotifications.entries.map((entry) {
                  return _buildGroupCard(entry.key, entry.value);
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(NotificationStateController state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleGreenGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notification Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.softWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkSlateGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock, size: 12, color: AppColors.neonGreen),
                    SizedBox(width: 4),
                    Text(
                      '36h Active Window',
                      style: TextStyle(fontSize: 11, color: AppColors.neonGreen, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip('Total Alerts', state.totalCount.toString(), AppColors.neonGreen),
              const SizedBox(width: 12),
              _buildStatChip('High Priority', state.highPriorityCount.toString(), AppColors.alertRed),
              const SizedBox(width: 12),
              _buildStatChip('Apps', state.appCounts.keys.length.toString(), AppColors.softWhite),
            ],
          ),
          const SizedBox(height: 16),
          // Ask Ben action prompt
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSlateGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGreen.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.neonGreen, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ask "What did I miss?" in the Assistant tab for an AI-powered digest.',
                    style: TextStyle(fontSize: 13, color: AppColors.softWhite),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.neonGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.darkCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.subtleGreenGrey),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String appName, List<NotificationItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.subtleGreenGrey),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: AppColors.mutedGrey,
        iconColor: AppColors.neonGreen,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkSlateGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apps_rounded, size: 20, color: AppColors.neonGreen),
        ),
        title: Text(
          appName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.softWhite),
        ),
        subtitle: Text(
          '${items.length} notification${items.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
        ),
        children: items.map((item) => _buildNotificationCard(item, embedded: true)).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, {bool embedded = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailsScreen(notificationId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(embedded ? 0 : 14),
      child: Container(
        margin: embedded ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) : const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: embedded ? AppColors.darkCharcoal : AppColors.forestCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isHighPriority ? AppColors.alertRed.withAlpha(80) : AppColors.subtleGreenGrey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!embedded) ...[
                        Text(
                          item.appName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.senderName != null) ...[
                        Text(
                          item.senderName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.softWhite,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PriorityBadge(priority: item.priority),
              ],
            ),
            if (item.title != null && item.title!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.softWhite,
                ),
              ),
            ],
            if (item.body != null && item.body!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.3),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(item.receivedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.disabledText),
                ),
                const Row(
                  children: [
                    Text('Details', style: TextStyle(fontSize: 12, color: AppColors.neonGreen)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: AppColors.neonGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAndroid) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleGreenGrey),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 54, color: AppColors.neonGreen),
          const SizedBox(height: 16),
          const Text(
            "You're all caught up",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.softWhite),
          ),
          const SizedBox(height: 8),
          Text(
            isAndroid
                ? 'New notifications will automatically appear here as they arrive on your device.'
                : 'Share or paste notification text to organize and summarize it with Ben.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showManualAddDialog,
            icon: const Icon(Icons.add, size: 18, color: AppColors.neonGreen),
            label: const Text('Add Test Alert', style: TextStyle(color: AppColors.neonGreen)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
