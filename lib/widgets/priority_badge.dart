import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final p = priority.toLowerCase();
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (p == 'high') {
      bg = AppColors.alertRed.withAlpha(40);
      fg = AppColors.alertRed;
      icon = Icons.priority_high;
      label = 'High';
    } else if (p == 'low') {
      bg = AppColors.subtleGreenGrey;
      fg = AppColors.mutedGrey;
      icon = Icons.arrow_downward;
      label = 'Low';
    } else {
      bg = AppColors.darkSlateGreen;
      fg = AppColors.softGreen;
      icon = Icons.check_circle_outline;
      label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fg.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
