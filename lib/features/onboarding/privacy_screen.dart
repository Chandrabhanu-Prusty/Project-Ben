import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/ben_button.dart';

class PrivacyIntroductionScreen extends StatelessWidget {
  const PrivacyIntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Privacy & Data Control'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How Ben protects your personal data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.softWhite,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Before enabling notification access, review our transparent privacy commitments.',
                style: TextStyle(fontSize: 14, color: AppColors.mutedGrey, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Feature cards
              _buildPrivacyCard(
                icon: Icons.storage_rounded,
                title: 'Local On-Device Storage',
                description:
                    'All your notification contents, chat sessions, and assistant queries are stored directly in SQLite on this phone. We do not maintain a cloud notification database.',
              ),
              const SizedBox(height: 16),

              _buildPrivacyCard(
                icon: Icons.timer_outlined,
                title: 'Strict 36-Hour Retention',
                description:
                    'Every notification record, conversation, and message is hard-limited to 36 hours from creation. Expired data is permanently pruned from device storage.',
              ),
              const SizedBox(height: 16),

              _buildPrivacyCard(
                icon: Icons.psychology_outlined,
                title: 'Minimal Cloud AI Summarization',
                description:
                    'When you ask Ben for a summary, only the necessary message previews are securely transmitted to the AI API. Full message content is never stored in server logs.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: BenButton(
            text: 'I Understand & Continue',
            type: BenButtonType.primary,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/onboarding/permissions');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.subtleGreenGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkSlateGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.neonGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
