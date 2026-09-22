import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'interactive_card.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
    this.showEmoji = false,
    this.showIcon = false,
  });

  final String status;
  final bool showDot;
  final bool showEmoji;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final icon = AppTheme.statusIcon(status);
    final formattedStatus = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon || showEmoji) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            GlowingPulseDot(
              color: color,
              size: 6,
              isPulsing: status.toUpperCase() == 'ACTIVE' ||
                  status.toUpperCase() == 'OVERDUE',
            ),
            const SizedBox(width: 6),
          ],
          Text(
            formattedStatus,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

