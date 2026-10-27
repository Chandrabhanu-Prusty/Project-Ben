import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/assistant_state.dart';
import '../../state/notification_state.dart';
import '../../widgets/speaking_indicator.dart';

class AssistantScreen extends StatefulWidget {
  final String? initialPrompt;

  const AssistantScreen({super.key, this.initialPrompt});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'What did I miss?',
    'Any important emails?',
    'Show high priority alerts',
    'Summarize college updates',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        _sendPrompt(widget.initialPrompt!);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt(String text) {
    final notifs = context.read<NotificationStateController>().notifications;
    context.read<AssistantStateController>().sendMessage(text, notifs);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final assistant = context.watch<AssistantStateController>();
    final notifs = context.watch<NotificationStateController>().notifications;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Row(
          children: [
            SpeakingIndicator(
              isSpeaking: assistant.isSpeaking,
              isThinking: assistant.isLoading,
              size: 26,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ben Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  assistant.isSpeaking
                      ? 'Speaking...'
                      : assistant.isLoading
                          ? 'Thinking...'
                          : 'Online & Ready',
                  style: TextStyle(
                    fontSize: 11,
                    color: assistant.isSpeaking
                        ? AppColors.neonGreen
                        : assistant.isLoading
                            ? AppColors.softGreen
                            : AppColors.mutedGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Conversation',
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.neonGreen),
            onPressed: () => assistant.startNewConversation(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List or Empty Suggestions
            Expanded(
              child: assistant.messages.isEmpty
                  ? _buildEmptySuggestions()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: assistant.messages.length,
                      itemBuilder: (context, index) {
                        final msg = assistant.messages[index];
                        return _buildChatBubble(msg, assistant);
                      },
                    ),
            ),

            if (assistant.isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SpeakingIndicator(isThinking: true, size: 20),
                    const SizedBox(width: 10),
                    const Text('Ben is analyzing notifications...', style: TextStyle(color: AppColors.mutedGrey, fontSize: 13)),
                  ],
                ),
              ),
            ],

            if (assistant.isRecordingVoice) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alertRed),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: AppColors.alertRed, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recording voice query... Tap microphone again to finish',
                      style: TextStyle(color: AppColors.softWhite, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.darkCharcoal,
                border: Border(top: BorderSide(color: AppColors.subtleGreenGrey)),
              ),
              child: Row(
                children: [
                  // Microphone Button
                  IconButton(
                    tooltip: 'Speak to Ben',
                    icon: Icon(
                      assistant.isRecordingVoice ? Icons.mic : Icons.mic_none,
                      color: assistant.isRecordingVoice ? AppColors.alertRed : AppColors.neonGreen,
                      size: 26,
                    ),
                    onPressed: () => assistant.toggleVoiceRecording(notifs),
                  ),

                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppColors.softWhite, fontSize: 15),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          _sendPrompt(v);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Ask Ben about your alerts...',
                        hintStyle: const TextStyle(color: AppColors.mutedGrey, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.darkSlateGreen,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  IconButton(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send_rounded, color: AppColors.neonGreen),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        _sendPrompt(text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkSlateGreen,
              border: Border.all(color: AppColors.neonGreen, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.psychology, size: 36, color: AppColors.neonGreen),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'What would you like to know?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.softWhite),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask Ben anything about your recent alerts or tap a suggested prompt below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
          ),
          const SizedBox(height: 28),
          ..._suggestedPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendPrompt(prompt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.forestCharcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.subtleGreenGrey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prompt,
                        style: const TextStyle(fontSize: 14, color: AppColors.softWhite, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.neonGreen),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatBubble(dynamic msg, AssistantStateController assistant) {
    final isUser = msg.isUser as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkSlateGreen,
                border: Border.all(color: AppColors.neonGreen, width: 1.5),
              ),
              child: const Center(
                child: Text('B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonGreen)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.forestCharcoal : AppColors.darkSlateGreen,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? Radius.zero : null,
                  bottomLeft: !isUser ? Radius.zero : null,
                ),
                border: Border.all(
                  color: isUser ? AppColors.subtleGreenGrey : AppColors.neonGreen.withAlpha(70),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? AppColors.softWhite : AppColors.softWhite,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => assistant.readAloud(msg.content as String),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  assistant.isSpeaking ? Icons.stop : Icons.volume_up,
                                  size: 16,
                                  color: AppColors.neonGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  assistant.isSpeaking ? 'Stop' : 'Listen',
                                  style: const TextStyle(fontSize: 12, color: AppColors.neonGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
