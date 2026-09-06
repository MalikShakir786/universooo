import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../theme/app_theme.dart';

class UrgencyBadge extends StatelessWidget {
  final ApplicationUrgency urgency;
  final String? customLabel;
  final double fontSize;

  const UrgencyBadge({
    super.key,
    required this.urgency,
    this.customLabel,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, defaultLabel) = AppTheme.getUrgencyColors(urgency, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: fg.withAlpha(isDark ? 80 : 50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            customLabel ?? defaultLabel,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
