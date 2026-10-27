import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/notification_bridge.dart';
import '../../data/services/overlay_service.dart';
import '../../state/auth_state.dart';
import '../../widgets/ben_button.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _overlayGranted = false;
  bool _micGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.isGranted;

    bool notif = false;
    bool overlay = false;

    if (!kIsWeb && Platform.isAndroid) {
      notif = await NotificationBridge.isNotificationAccessGranted();
      overlay = await OverlayService.isOverlayPermissionGranted();
    }

    if (mounted) {
      setState(() {
        _micGranted = mic;
        _notificationGranted = notif;
        _overlayGranted = overlay;
      });
    }
  }

  Future<void> _requestNotificationAccess() async {
    if (!kIsWeb && Platform.isAndroid) {
      await NotificationBridge.openNotificationSettings();
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      await OverlayService.requestOverlayPermission();
    }
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      setState(() {
        _micGranted = status.isGranted;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final authState = context.read<AuthStateController>();
    await authState.completeOnboarding();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Permission Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enable Ben Assistant',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.softWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAndroid
                    ? 'Grant permissions to allow Ben to read notifications and float above your apps.'
                    : 'Configure supported voice permissions for Ben on your iOS device.',
                style: const TextStyle(fontSize: 14, color: AppColors.mutedGrey, height: 1.4),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  children: [
                    if (isAndroid) ...[
                      _buildPermissionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Access',
                        subtitle: 'Required to automatically capture, group, and summarize alerts.',
                        isGranted: _notificationGranted,
                        onAction: _requestNotificationAccess,
                        actionLabel: 'Open Settings',
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionTile(
                        icon: Icons.picture_in_picture_alt_rounded,
                        title: 'Floating Overlay (Draggable)',
                        subtitle: 'Displays the draggable Ben icon above other apps for quick access.',
                        isGranted: _overlayGranted,
                        onAction: _requestOverlayPermission,
                        actionLabel: 'Grant Overlay',
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.forestCharcoal,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.subtleGreenGrey),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.softGreen, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'iOS does not allow third-party apps to intercept other apps’ notifications. You can paste or share text into Ben anytime for AI summaries.',
                                style: TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildPermissionTile(
                      icon: Icons.mic_none_rounded,
                      title: 'Microphone Access',
                      subtitle: 'Used when asking "What did I miss?" with hands-free voice input.',
                      isGranted: _micGranted,
                      onAction: _requestMicPermission,
                      actionLabel: 'Allow Mic',
                    ),
                  ],
                ),
              ),

              BenButton(
                text: 'Continue to Ben',
                type: BenButtonType.primary,
                onPressed: _finishOnboarding,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  !_notificationGranted && isAndroid
                      ? 'You can continue in limited mode and enable permissions later in Settings.'
                      : 'All set! You can change permissions anytime in Settings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forestCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? AppColors.neonGreen.withAlpha(80) : AppColors.subtleGreenGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkSlateGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isGranted ? AppColors.neonGreen : AppColors.softWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softWhite,
                  ),
                ),
              ),
              if (isGranted)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.neonGreen, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Enabled',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neonGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                    side: const BorderSide(color: AppColors.neonGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
