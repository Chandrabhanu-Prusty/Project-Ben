import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_state.dart';
import '../../widgets/ben_button.dart';
import '../../widgets/ben_text_field.dart';

class OtpVerificationScreen extends StatefulWidget {
  final bool isPhone;
  final String destination;

  const OtpVerificationScreen({
    super.key,
    required this.isPhone,
    required this.destination,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _secondsRemaining = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthStateController>();
    final token = _otpController.text.trim();

    bool success;
    if (widget.isPhone) {
      success = await auth.verifyPhoneOtp(widget.destination, token);
    } else {
      success = await auth.verifyEmailOtp(widget.destination, token);
    }

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding/privacy', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateController>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Verify Code'),
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
                  'Enter verification code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit verification code to ${widget.destination}.',
                  style: const TextStyle(fontSize: 14, color: AppColors.mutedGrey, height: 1.4),
                ),
                const SizedBox(height: 32),

                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.alertRed.withAlpha(120)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 20, color: AppColors.alertRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppColors.softWhite, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                BenTextField(
                  controller: _otpController,
                  label: '6-Digit Code',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().length < 6 ? 'Enter full 6-digit code' : null,
                ),

                const SizedBox(height: 24),

                BenButton(
                  text: 'Verify and Continue',
                  type: BenButtonType.primary,
                  isLoading: auth.isLoading,
                  onPressed: _verify,
                ),

                const SizedBox(height: 24),

                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          'Resend code in ${_secondsRemaining}s',
                          style: const TextStyle(color: AppColors.mutedGrey, fontSize: 14),
                        )
                      : TextButton(
                          onPressed: () {
                            _startTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New verification code requested.'),
                                backgroundColor: AppColors.darkSlateGreen,
                              ),
                            );
                          },
                          child: const Text('Resend Code'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
