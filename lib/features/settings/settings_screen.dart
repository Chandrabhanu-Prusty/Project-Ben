import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/notification_bridge.dart';
import '../../data/services/overlay_service.dart';
import '../../state/assistant_state.dart';
import '../../state/auth_state.dart';
import '../../state/notification_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _overlayEnabled = false;
  double _overlayOpacity = 0.9;
  bool _notificationAccess = false;
  bool _overlayPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await OverlayService.isOverlayEnabledPref();
    final opacity = await OverlayService.getOverlayOpacityPref();

    bool notif = false;
    bool overlayPerm = false;
    if (!kIsWeb && Platform.isAndroid) {
      notif = await NotificationBridge.isNotificationAccessGranted();
      overlayPerm = await OverlayService.isOverlayPermissionGranted();
    }

    if (mounted) {
      setState(() {
        _overlayEnabled = enabled;
        _overlayOpacity = opacity;
        _notificationAccess = notif;
        _overlayPermission = overlayPerm;
      });
    }
  }

  Future<void> _toggleOverlay(bool value) async {
    if (!kIsWeb && Platform.isAndroid) {
      if (value) {
        if (!_overlayPermission) {
          await OverlayService.requestOverlayPermission();
          return;
        }
        await OverlayService.showOverlay();
      } else {
        await OverlayService.hideOverlay();
      }
    }
    setState(() => _overlayEnabled = value);
  }

  Future<void> _updateOpacity(double value) async {
    setState(() => _overlayOpacity = value);
    await OverlayService.setOpacity(value);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestCharcoal,
        title: const Text('Sign Out', style: TextStyle(color: AppColors.softWhite)),
        content: const Text(
          'Signing out will clear local notification and conversation records for this device per your privacy choice.',
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
            child: const Text('Sign Out', style: TextStyle(color: AppColors.softWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthStateController>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forestCharcoal,
        title: const Text('Change Password', style: TextStyle(color: AppColors.softWhite)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: AppColors.softWhite),
            decoration: const InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter at least 6 characters',
            ),
            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.deepBlack,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AuthStateController>().changePassword(passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Password updated successfully in Supabase!' : 'Failed to update password',
            ),
            backgroundColor: success ? AppColors.neonGreen : AppColors.alertRed,
          ),
        );
      }
    }
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateController>();
    final assistant = context.watch<AssistantStateController>();
    final notifState = context.read<NotificationStateController>();
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forestCharcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleGreenGrey),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.darkSlateGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: AppColors.neonGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.email ?? 'Authenticated User',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.softWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${auth.userId ?? "Unknown"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.disabledText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.subtleGreenGrey),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonGreen,
                        side: const BorderSide(color: AppColors.neonGreen),
                      ),
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: const Text('Change Password'),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertRed,
                        side: const BorderSide(color: AppColors.alertRed),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      onPressed: _confirmSignOut,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Personalization Section
            _buildSectionHeader('Personalization'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forestCharcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleGreenGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferred Title / Salutation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.softWhite),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'How Ben addresses you when speaking ("Master", "Sir", "Ma\'am").',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Master', 'Sir', "Ma'am"].map((title) {
                      final isSelected = assistant.honorific == title;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(title),
                          selected: isSelected,
                          selectedColor: AppColors.neonGreen,
                          backgroundColor: AppColors.darkSlateGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.deepBlack : AppColors.softWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            context.read<AssistantStateController>().setHonorific(title);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Android Floating Assistant Section
            if (isAndroid) ...[
              _buildSectionHeader('Android Floating Assistant'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.forestCharcoal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.subtleGreenGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Enable Draggable Floating Icon',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.softWhite),
                      ),
                      subtitle: const Text(
                        'Keep Ben visible over other apps. Tap to speak directly with Ben outside the app.',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                      ),
                      activeColor: AppColors.neonGreen,
                      value: _overlayEnabled,
                      onChanged: _toggleOverlay,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Icon Opacity',
                      style: TextStyle(fontSize: 13, color: AppColors.softWhite, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.opacity, size: 18, color: AppColors.mutedGrey),
                        Expanded(
                          child: Slider(
                            value: _overlayOpacity,
                            min: 0.2,
                            max: 1.0,
                            activeColor: AppColors.neonGreen,
                            inactiveColor: AppColors.subtleGreenGrey,
                            onChanged: _updateOpacity,
                          ),
                        ),
                        Text(
                          '${(_overlayOpacity * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, color: AppColors.softWhite),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // System Permissions Section
            _buildSectionHeader('Permissions'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.forestCharcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleGreenGrey),
              ),
              child: Column(
                children: [
                  if (isAndroid) ...[
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.neonGreen),
                      title: const Text('Notification Listener Access', style: TextStyle(color: AppColors.softWhite, fontSize: 14)),
                      subtitle: Text(_notificationAccess ? 'Enabled' : 'Disabled - Tap to configure', style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedGrey),
                      onTap: () => NotificationBridge.openNotificationSettings(),
                    ),
                    const Divider(color: AppColors.subtleGreenGrey, height: 1),
                    ListTile(
                      leading: const Icon(Icons.layers_outlined, color: AppColors.neonGreen),
                      title: const Text('Display Over Other Apps', style: TextStyle(color: AppColors.softWhite, fontSize: 14)),
                      subtitle: Text(_overlayPermission ? 'Granted' : 'Denied - Tap to grant', style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedGrey),
                      onTap: () => OverlayService.requestOverlayPermission(),
                    ),
                    const Divider(color: AppColors.subtleGreenGrey, height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.mic_outlined, color: AppColors.neonGreen),
                    title: const Text('Microphone Permission', style: TextStyle(color: AppColors.softWhite, fontSize: 14)),
                    subtitle: const Text('Voice-first assistant queries', style: TextStyle(fontSize: 12, color: AppColors.mutedGrey)),
                    trailing: const Icon(Icons.check, color: AppColors.neonGreen),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy and Retention Section
            _buildSectionHeader('Data Retention & Privacy'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forestCharcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleGreenGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.neonGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '36-Hour Auto Expiration Active',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.softWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All notification records and assistant conversation histories are stored in local SQLite on this device only and expire after 36 hours.',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedGrey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.subtleGreenGrey),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear All Notifications From Device'),
                    onPressed: () async {
                      await notifState.clearAll();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All local notifications cleared.')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Ben v1.0 • Personal Notification & Voice Assistant',
                style: TextStyle(fontSize: 12, color: AppColors.disabledText),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.neonGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
