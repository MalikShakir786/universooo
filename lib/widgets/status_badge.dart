import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = AppTheme.getStatusColors(status, isDark);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fg.withAlpha(isDark ? 80 : 50),
          width: 0.8,
        ),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
