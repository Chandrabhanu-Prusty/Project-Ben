import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../state/assistant_state.dart';
import '../../state/auth_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ConversationRepository _repository = ConversationRepository();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final auth = context.read<AuthStateController>();
    if (auth.userId == null) return;

    setState(() => _isLoading = true);
    final list = await _repository.getConversations(ownerUserId: auth.userId!);
    if (mounted) {
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConversation(String id) async {
    final auth = context.read<AuthStateController>();
    if (auth.userId == null) return;
    await _repository.deleteConversation(id, auth.userId!);
    await _loadConversations();
  }

  Future<void> _clearAll() async {
    final auth = context.read<AuthStateController>();
    if (auth.userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestCharcoal,
        title: const Text('Clear Conversation History?', style: TextStyle(color: AppColors.softWhite)),
        content: const Text(
          'This will permanently delete all your recent assistant conversations from local storage.',
          style: TextStyle(color: AppColors.mutedGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.softWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearAllConversations(auth.userId!);
      await _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Conversation History'),
        actions: [
          if (_conversations.isNotEmpty)
            IconButton(
              tooltip: 'Clear History',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.alertRed),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
            : _conversations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.neonGreen,
                    backgroundColor: AppColors.darkCharcoal,
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        return _buildConversationCard(conv);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conv) {
    final expiresHours = DateTime.fromMillisecondsSinceEpoch(conv.expiresAt)
        .difference(DateTime.now())
        .inHours;

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.alertRed,
        child: const Icon(Icons.delete, color: AppColors.softWhite),
      ),
      onDismissed: (_) => _deleteConversation(conv.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.forestCharcoal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.subtleGreenGrey),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkSlateGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: AppColors.neonGreen, size: 20),
          ),
          title: Text(
            conv.title ?? 'Notification Session',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.softWhite),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.mutedGrey),
                const SizedBox(width: 4),
                Text(
                  expiresHours > 0 ? 'Expires in ~${expiresHours}h' : 'Expiring soon',
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.mutedGrey, size: 18),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await context.read<AssistantStateController>().loadConversation(conv.id);
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Conversation loaded into Assistant tab.'),
                backgroundColor: AppColors.darkSlateGreen,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.mutedGrey),
            const SizedBox(height: 18),
            const Text(
              'No recent conversations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.softWhite),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask Ben a question in the Assistant tab to start your recent conversation history. History is stored locally for up to 36 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
