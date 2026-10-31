import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/ben_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon branding
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGreen.withAlpha(120),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/omnitrix_logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Meet Ben.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.softWhite,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your phone, your notifications, your personal AI assistant. Stop opening dozens of apps—ask Ben what you missed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedGrey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              BenButton(
                text: 'Get Started',
                type: BenButtonType.primary,
                onPressed: () {
                  Navigator.pushNamed(context, '/auth/signup');
                },
              ),
              const SizedBox(height: 12),
              BenButton(
                text: 'I already have an account',
                type: BenButtonType.secondary,
                onPressed: () {
                  Navigator.pushNamed(context, '/auth/login');
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Your notification data is stored locally and expires automatically after 36 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
