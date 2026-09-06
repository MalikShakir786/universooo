import 'package:flutter/material.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.subtitle = '',
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorderColor = widget.isSelected
        ? widget.color
        : (_isHovered
            ? widget.color.withAlpha(120)
            : (isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0)));

    final cardBg = isDark ? const Color(0xFF1E2129) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: baseBorderColor,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (_isHovered || widget.isSelected)
                BoxShadow(
                  color: widget.color.withAlpha(widget.isSelected ? 40 : 25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(isDark ? 50 : 35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 17,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.subtitle.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
