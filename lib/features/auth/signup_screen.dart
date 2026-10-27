import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_state.dart';
import '../../widgets/ben_button.dart';
import '../../widgets/ben_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _emailConfirmPasswordController = TextEditingController();

  final _phoneController = TextEditingController();
  final _phonePasswordController = TextEditingController();
  final _phoneConfirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPhone = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    _emailConfirmPasswordController.dispose();
    _phoneController.dispose();
    _phonePasswordController.dispose();
    _phoneConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signupEmail() async {
    if (!_formKeyEmail.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final auth = context.read<AuthStateController>();
    final success = await auth.signUpWithEmail(email, _emailPasswordController.text);
    if (success && mounted) {
      Navigator.pushNamed(
        context,
        '/auth/verify-email',
        arguments: {'email': email},
      );
    }
  }

  Future<void> _signupPhone() async {
    if (!_formKeyPhone.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    final auth = context.read<AuthStateController>();
    final success = await auth.signUpWithPhone(phone, _phonePasswordController.text);
    if (success && mounted) {
      Navigator.pushNamed(
        context,
        '/auth/verify-phone',
        arguments: {'phone': phone},
      );
    }
  }

  Future<void> _signupGoogle() async {
    final auth = context.read<AuthStateController>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      if (auth.onboardingCompleted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding/privacy', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateController>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get started with Ben',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.softWhite,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your personal assistant profile.',
                style: TextStyle(fontSize: 14, color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 24),

              BenButton(
                text: 'Sign up with Google',
                type: BenButtonType.secondary,
                icon: Icons.g_mobiledata,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _signupGoogle,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.subtleGreenGrey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedGrey.withAlpha(150)),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.subtleGreenGrey)),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Bar for Email / Phone
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSlateGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: AppColors.deepBlack,
                  unselectedLabelColor: AppColors.mutedGrey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Email'),
                    Tab(text: 'Mobile Number'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                const SizedBox(height: 16),
              ],

              SizedBox(
                height: 310,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Email Signup Form
                    Form(
                      key: _formKeyEmail,
                      child: Column(
                        children: [
                          BenTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'your.name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 14),
                          BenTextField(
                            controller: _emailPasswordController,
                            label: 'Create Password',
                            isPassword: true,
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 14),
                          BenTextField(
                            controller: _emailConfirmPasswordController,
                            label: 'Confirm Password',
                            isPassword: true,
                            validator: (v) {
                              if (v != _emailPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Phone Signup Form
                    Form(
                      key: _formKeyPhone,
                      child: Column(
                        children: [
                          BenTextField(
                            controller: _phoneController,
                            label: 'Mobile Number (with country code)',
                            hint: '+919876543210',
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.length < 8 ? 'Enter a valid phone number' : null,
                          ),
                          const SizedBox(height: 14),
                          BenTextField(
                            controller: _phonePasswordController,
                            label: 'Create Password',
                            isPassword: true,
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 14),
                          BenTextField(
                            controller: _phoneConfirmPasswordController,
                            label: 'Confirm Password',
                            isPassword: true,
                            validator: (v) {
                              if (v != _phonePasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              BenButton(
                text: 'Create Account',
                type: BenButtonType.primary,
                isLoading: auth.isLoading,
                onPressed: () {
                  if (_tabController.index == 0) {
                    _signupEmail();
                  } else {
                    _signupPhone();
                  }
                },
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.mutedGrey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/auth/login'),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
