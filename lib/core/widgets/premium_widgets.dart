import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmojiIconButton — circular gradient background with emoji + label
// ─────────────────────────────────────────────────────────────────────────────

class EmojiIconButton extends StatefulWidget {
  const EmojiIconButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<EmojiIconButton> createState() => _EmojiIconButtonState();
}

class _EmojiIconButtonState extends State<EmojiIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SummaryCard — emoji + title + value + optional trend arrow
// ─────────────────────────────────────────────────────────────────────────────

class SummaryCard extends StatefulWidget {
  const SummaryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.13),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon in colored pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const Spacer(),
              Text(
                widget.value,
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
                      widget.label,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (widget.trend != null && widget.trendUp != null) ...[
                    Icon(
                      widget.trendUp! ? Icons.trending_up : Icons.trending_down,
                      color: widget.trendUp! ? AppTheme.successColor : AppTheme.errorColor,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.trend!,
                      style: TextStyle(
                        color: widget.trendUp! ? AppTheme.successColor : AppTheme.errorColor,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GreetingHeader — time-based greeting with avatar initials
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

  static String _getTimeEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
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
    final emoji = _getTimeEmoji();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle with initials
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                      '$greeting, $name $emoji',
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
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (role != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                      ),
                      child: Text(
                        role!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
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
