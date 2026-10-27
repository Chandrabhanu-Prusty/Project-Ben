import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final authState = context.read<AuthStateController>();

    if (authState.isAuthenticated) {
      if (authState.onboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding/privacy');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkCharcoal,
                border: Border.all(color: AppColors.neonGreen, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '10',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonGreen,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BEN',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: AppColors.softWhite,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Personal AI Notification Assistant',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
