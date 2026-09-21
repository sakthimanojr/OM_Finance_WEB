import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(adminSummaryProvider);
    final user = ref.watch(authProvider).user;
    final displayName = user?.phone ?? 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Premium Admin Header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_outlined,
                      color: Colors.white, size: 18),
                ),
                tooltip: 'Logout',
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: GreetingHeader(
                name: displayName,
                subtitle: 'OM Finance Admin Panel',
                role: '👑 ADMIN',
              ),
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -40,
                      top: -30,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      right: 60,
                      bottom: -50,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    Positioned(
                      left: -25,
                      top: 20,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    // Crown emoji watermark
                    Positioned(
                      right: 28,
                      top: 28,
                      child: Text(
                        '👑',
                        style: TextStyle(
                          fontSize: 52,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: true,
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async => ref.refresh(adminSummaryProvider),
              child: summaryAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(adminSummaryProvider),
                ),
                data: (summary) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    // ── Today's Summary Banner ───────────────────────
                    _TodaySummaryBanner(summary: summary),
                    const SizedBox(height: 20),

                    // ── Stat Cards Grid (with emojis) ─────────────────
                    const _SectionTitle('Overview'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        SummaryCard(
                          emoji: '👥',
                          label: 'Active Customers',
                          value: '${summary.totalCustomers}',
                          color: AppTheme.primaryColor,
                          onTap: () => context
                              .push('/admin/customers?status=ACTIVE'),
                        ),
                        SummaryCard(
                          emoji: '📋',
                          label: 'Active Loans',
                          value: '${summary.activeLoans}',
                          color: AppTheme.primaryLight,
                          onTap: () =>
                              context.push('/admin/loans?status=ACTIVE'),
                        ),
                        SummaryCard(
                          emoji: '⚠️',
                          label: 'Overdue Loans',
                          value: '${summary.overdueLoans}',
                          color: AppTheme.errorColor,
                          onTap: () =>
                              context.push('/admin/dues?tab=overdue'),
                        ),
                        SummaryCard(
                          emoji: '💰',
                          label: 'Collected This Month',
                          value: Formatters.currency(
                              summary.collectedThisMonth),
                          color: AppTheme.successColor,
                          onTap: () => context
                              .push('/admin/payments?month=current'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Portfolio Performance — Lime Accent Card ──────
                    _PortfolioCard(summary: summary),
                    const SizedBox(height: 24),

                    // ── Quick Actions — Emoji Grid ─────────────────────
                    const _SectionTitle('Management Actions'),
                    const SizedBox(height: 14),
                    _QuickActionsGrid(user: user, context: context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ── Today's Summary Banner ───────────────────────────────────────────────────

class _TodaySummaryBanner extends StatelessWidget {
  const _TodaySummaryBanner({required this.summary});
  final dynamic summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    Formatters.date(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BannerStat(
                emoji: '🏦',
                label: 'Total Disbursed',
                value: Formatters.currency(summary.totalDisbursed),
              ),
              const SizedBox(width: 12),
              _BannerStat(
                emoji: '✅',
                label: 'Total Collected',
                value: Formatters.currency(summary.totalCollected),
                valueColor: AppTheme.accentLime,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BannerStat(
                emoji: '⏳',
                label: 'Pending Dues',
                value: '${summary.pendingDuesCount}',
              ),
              const SizedBox(width: 12),
              _BannerStat(
                emoji: '🔥',
                label: 'Overdue Dues',
                value: '${summary.overdueDuesCount}',
                valueColor: const Color(0xFFFFB3B3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.emoji,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String emoji;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: AppTheme.glassmorphismCard(
          opacity: 0.14,
          borderOpacity: 0.2,
          radius: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portfolio Card (Lime-Yellow accent) ──────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.summary});
  final dynamic summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.accentLime,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentLime.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📈 Portfolio Performance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.buttonBlack.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_outline,
                    color: AppTheme.buttonBlack, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LimeStatRow(
            '🏦 Total Disbursed',
            Formatters.currency(summary.totalDisbursed),
            isBold: true,
          ),
          const SizedBox(height: 10),
          _LimeStatRow(
            '💵 Total Collected',
            Formatters.currency(summary.totalCollected),
            valueColor: AppTheme.successColor,
            isBold: true,
          ),
          const SizedBox(height: 10),
          _LimeStatRow(
            '⏳ Pending Count',
            '${summary.pendingDuesCount}',
          ),
          const SizedBox(height: 10),
          _LimeStatRow(
            '🔥 Overdue Count',
            '${summary.overdueDuesCount}',
            valueColor: AppTheme.errorColor,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _LimeStatRow extends StatelessWidget {
  const _LimeStatRow(this.label, this.value,
      {this.valueColor, this.isBold = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textDark.withOpacity(0.65),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.user, required this.context});
  final dynamic user;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _QuickActionCard(
          emoji: '👤',
          label: 'Customers',
          color: AppTheme.primaryColor,
          onTap: () => context.push('/admin/customers'),
        ),
        _QuickActionCard(
          emoji: '🧾',
          label: 'New Loan',
          color: AppTheme.primaryLight,
          onTap: () => context.push('/admin/loans/new'),
        ),
        _QuickActionCard(
          emoji: '🔔',
          label: 'Due Logs',
          color: AppTheme.warningColor,
          onTap: () => context.push('/admin/dues'),
        ),
        _QuickActionCard(
          emoji: '📊',
          label: 'Reports',
          color: AppTheme.accentColor,
          onTap: () => context.push('/admin/reports'),
        ),
        _QuickActionCard(
          emoji: '🏦',
          label: 'Chit Funds',
          color: AppTheme.successColor,
          onTap: () => context.push('/admin/chit-funds'),
        ),
        _QuickActionCard(
          emoji: '📜',
          label: 'Audit Logs',
          color: AppTheme.textMuted,
          onTap: () => context.push('/admin/audit-logs'),
        ),
        if (user?.isSuperAdmin == true)
          _QuickActionCard(
            emoji: '⚙️',
            label: 'Admin Mgmt',
            color: AppTheme.primaryDark,
            onTap: () => context.push('/admin/management'),
          ),
        _QuickActionCard(
          emoji: '🗂️',
          label: 'Closed Loans',
          color: AppTheme.textMuted,
          onTap: () => context.push('/admin/closed-loans'),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
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
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(widget.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
