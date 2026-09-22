import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'interactive_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActionIconButton — circular gradient background with modern icon + label
// ─────────────────────────────────────────────────────────────────────────────

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveBounce(
      onTap: onTap,
      scaleFactor: 0.92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Backwards-compatible alias for existing screens
class EmojiIconButton extends StatelessWidget {
  const EmojiIconButton({
    super.key,
    this.emoji,
    this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final String? emoji;
  final IconData? icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionIconButton(
      icon: icon ?? _fallbackIcon(emoji, label),
      label: label,
      gradient: gradient,
      onTap: onTap,
    );
  }

  static IconData _fallbackIcon(String? emoji, String label) {
    final l = label.toLowerCase();
    if (l.contains('loan')) return Icons.assignment_outlined;
    if (l.contains('payment')) return Icons.receipt_long_outlined;
    if (l.contains('chit')) return Icons.account_balance_outlined;
    if (l.contains('profile') || l.contains('customer')) {
      return Icons.person_outline_rounded;
    }
    if (l.contains('report') || l.contains('analytics')) {
      return Icons.bar_chart_rounded;
    }
    if (l.contains('setting') || l.contains('mgmt')) {
      return Icons.settings_outlined;
    }
    return Icons.apps_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SummaryCard — Icon + title + value + optional trend arrow + touching effect
// ─────────────────────────────────────────────────────────────────────────────

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    this.emoji,
    this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String? emoji;
  final IconData? icon;
  final String label;
  final String value;
  final Color color;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  IconData get _resolvedIcon {
    if (icon != null) return icon!;
    final l = label.toLowerCase();
    if (l.contains('customer')) return Icons.groups_rounded;
    if (l.contains('active loan')) return Icons.assignment_outlined;
    if (l.contains('overdue')) return Icons.warning_amber_rounded;
    if (l.contains('collected') || l.contains('collection')) {
      return Icons.payments_outlined;
    }
    if (l.contains('disbursed')) return Icons.account_balance_wallet_outlined;
    if (l.contains('profit')) return Icons.trending_up_rounded;
    return Icons.insights_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveBounce(
      onTap: onTap,
      scaleFactor: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean vector icon in tinted rounded pill
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _resolvedIcon,
                color: color,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (trend != null && trendUp != null) ...[
                  Icon(
                    trendUp! ? Icons.trending_up : Icons.trending_down,
                    color: trendUp! ? AppTheme.successColor : AppTheme.errorColor,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend!,
                    style: TextStyle(
                      color:
                          trendUp! ? AppTheme.successColor : AppTheme.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GreetingHeader — modern greeting with avatar initials and clean badge
// ─────────────────────────────────────────────────────────────────────────────

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.role,
    this.textColor = Colors.white,
  });

  final String name;
  final String? subtitle;
  final String? role;
  final Color textColor;

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_twilight_rounded;
    if (hour < 17) return Icons.wb_sunny_rounded;
    return Icons.nightlight_round;
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final timeIcon = _getTimeIcon();
    final cleanRole = role?.replaceAll(RegExp(r'[^\w\s]'), '').trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle with initials
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getInitials(name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$greeting, $name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(timeIcon, color: Colors.white.withValues(alpha: 0.85), size: 15),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (subtitle != null)
                    Flexible(
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (cleanRole.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cleanRole.contains('ADMIN')
                                ? Icons.security_rounded
                                : Icons.account_circle_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cleanRole,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
