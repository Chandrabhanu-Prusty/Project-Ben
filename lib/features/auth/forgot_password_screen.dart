import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_state.dart';
import '../../widgets/ben_button.dart';
import '../../widgets/ben_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthStateController>();
    final success = await auth.sendPasswordReset(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateController>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.neonGreen),
                      const SizedBox(height: 20),
                      const Text(
                        'Recovery email sent',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.softWhite),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Follow the instructions sent to ${_emailController.text.trim()} to reset your password.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppColors.mutedGrey, height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      BenButton(
                        text: 'Enter New Password',
                        type: BenButtonType.primary,
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth/reset-password'),
                      ),
                      const SizedBox(height: 12),
                      BenButton(
                        text: 'Return to Login',
                        type: BenButtonType.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.softWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your registered email address and we will send you a password recovery link.',
                        style: TextStyle(fontSize: 14, color: AppColors.mutedGrey, height: 1.4),
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
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'your.name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 24),
                      BenButton(
                        text: 'Send Recovery Email',
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
