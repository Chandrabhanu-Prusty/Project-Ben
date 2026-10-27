import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_state.dart';
import '../../widgets/ben_button.dart';
import '../../widgets/ben_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthStateController>();
    final success = await auth.resetPassword(_passwordController.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please log in.'),
          backgroundColor: AppColors.darkSlateGreen,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/auth/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateController>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Set New Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create new password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softWhite,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter and confirm your new password below.',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedGrey),
                ),
                const SizedBox(height: 28),

                if (auth.errorMessage != null) ...[
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: AppColors.alertRed, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                ],

                BenTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  isPassword: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                BenTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  isPassword: true,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                BenButton(
                  text: 'Update Password',
                  type: BenButtonType.primary,
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
