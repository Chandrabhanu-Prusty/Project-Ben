import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum BenButtonType { primary, secondary, destructive }

class BenButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final BenButtonType type;
  final bool isLoading;
  final IconData? icon;

  const BenButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = BenButtonType.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: type == BenButtonType.primary
                  ? AppColors.neonGreen
                  : AppColors.softWhite,
            ),
          ),
        ),
      );
    }

    switch (type) {
      case BenButtonType.primary:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.deepBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.deepBlack),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
          ),
        );

      case BenButtonType.secondary:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.softWhite,
              backgroundColor: AppColors.darkSlateGreen,
              side: const BorderSide(color: AppColors.subtleGreenGrey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.softWhite),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
          ),
        );

      case BenButtonType.destructive:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.alertRed,
              side: const BorderSide(color: AppColors.alertRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.alertRed),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
          ),
        );
    }
  }
}
