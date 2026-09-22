import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/wave_container.dart';
import '../../core/widgets/interactive_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/network/api_client.dart';


class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(adminSummaryProvider);
    final user = ref.watch(authProvider).user;
    final displayName = user?.phone ?? 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async => ref.refresh(adminSummaryProvider),
        child: summaryAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(adminSummaryProvider),
          ),
          data: (summary) => CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
                pinned: true,
                floating: false,
                snap: false,
                toolbarHeight: 56,
                centerTitle: false,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'OM Finance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                    ),
                    tooltip: 'Refresh',
                    onPressed: () => ref.refresh(adminSummaryProvider),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Top Greeting Card with Wave ────────────────────
                    FadeSlideEntrance(
                      delayIndex: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedWaveBackground(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: GreetingHeader(
                              name: displayName,
                              subtitle: 'OM Finance Admin Portal',
                              role: 'ADMIN',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Financial Summary Banner with Waves ─────────────
                    FadeSlideEntrance(
                      delayIndex: 1,
                      child: _FinancialSummaryBanner(summary: summary),
                    ),
                    const SizedBox(height: 20),

                    // ── Stat Cards Grid (Modern Vector Icons) ───────────
                    FadeSlideEntrance(
                      delayIndex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                icon: Icons.groups_rounded,
                                label: 'Active Customers',
                                value: '${summary.totalCustomers}',
                                color: AppTheme.primaryColor,
                                onTap: () => context
                                    .push('/admin/customers?status=ACTIVE'),
                              ),
                              SummaryCard(
                                icon: Icons.assignment_outlined,
                                label: 'Active Loans',
                                value: '${summary.activeLoans}',
                                color: AppTheme.primaryLight,
                                onTap: () =>
                                    context.push('/admin/loans?status=ACTIVE'),
                              ),
                              SummaryCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Overdue Loans',
                                value: '${summary.overdueLoans}',
                                color: AppTheme.errorColor,
                                onTap: () =>
                                    context.push('/admin/dues?tab=overdue'),
                              ),
                              SummaryCard(
                                icon: Icons.payments_rounded,
                                label: 'Overall Collected',
                                value:
                                    Formatters.currency(summary.totalCollected),
                                color: AppTheme.successColor,
                                onTap: () => context.push('/admin/payments'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Quick Actions Grid ─────────────────────────────
                    FadeSlideEntrance(
                      delayIndex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('Management Actions'),
                          const SizedBox(height: 14),
                          _QuickActionsGrid(user: user, context: context),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
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

// ── Financial Summary Banner with Animated Wave ───────────────────────────────

class _FinancialSummaryBanner extends StatelessWidget {
  const _FinancialSummaryBanner({required this.summary});
  final dynamic summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedWaveBackground(
        waveOpacity1: 0.10,
        waveOpacity2: 0.06,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Disbursed, collected back & interest profit breakout',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _BannerStat(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Total Disbursed',
                    value: Formatters.currency(summary.totalDisbursed),
                  ),
                  const SizedBox(width: 12),
                  _BannerStat(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Collected Back',
                    value: Formatters.currency(summary.totalCollected),
                    valueColor: AppTheme.accentLime,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _BannerStat(
                    icon: Icons.trending_up_rounded,
                    label: 'Profit in Interest',
                    value: Formatters.currency(summary.totalInterestProfit),
                    valueColor: const Color(0xFF86EFAC),
                  ),
                  const SizedBox(width: 12),
                  _BannerStat(
                    icon: Icons.schedule_rounded,
                    label: 'Outstanding Balance',
                    value: Formatters.currency(summary.totalOutstanding),
                    valueColor: const Color(0xFFFFD580),
                  ),
                ],
              ),
              if (summary.totalDisbursed > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: AppTheme.glassmorphismCard(
                    opacity: 0.12,
                    borderOpacity: 0.18,
                    radius: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Collected from Disbursed',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${((summary.totalCollected / summary.totalDisbursed) * 100).clamp(0, 100).toStringAsFixed(1)}% recovered',
                            style: const TextStyle(
                              color: AppTheme.accentLime,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (summary.totalCollected / summary.totalDisbursed).clamp(0.0, 1.0).toDouble(),
                          backgroundColor: Colors.white.withValues(alpha: 0.20),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentLime),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: AppTheme.glassmorphismCard(
          opacity: 0.15,
          borderOpacity: 0.22,
          radius: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
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
          icon: Icons.people_alt_outlined,
          label: 'Customers',
          color: AppTheme.primaryColor,
          onTap: () => context.push('/admin/customers'),
        ),
        _QuickActionCard(
          icon: Icons.post_add_rounded,
          label: 'New Loan',
          color: AppTheme.primaryLight,
          onTap: () => context.push('/admin/loans/new'),
        ),
        _QuickActionCard(
          icon: Icons.notifications_none_rounded,
          label: 'Due Logs',
          color: AppTheme.warningColor,
          onTap: () => context.push('/admin/dues'),
        ),
        _QuickActionCard(
          icon: Icons.insights_rounded,
          label: 'Reports',
          color: AppTheme.accentColor,
          onTap: () => context.push('/admin/reports'),
        ),
        _QuickActionCard(
          icon: Icons.account_balance_outlined,
          label: 'Chit Funds',
          color: AppTheme.successColor,
          onTap: () => context.push('/admin/chit-funds'),
        ),
        _QuickActionCard(
          icon: Icons.history_edu_rounded,
          label: 'Audit Logs',
          color: AppTheme.textMuted,
          onTap: () => context.push('/admin/audit-logs'),
        ),
        if (user?.isSuperAdmin == true) ...[
          _QuickActionCard(
            icon: Icons.manage_accounts_outlined,
            label: 'Admin Mgmt',
            color: AppTheme.primaryDark,
            onTap: () => context.push('/admin/management'),
          ),
          _QuickActionCard(
            icon: Icons.file_download_outlined,
            label: 'Import CSV',
            color: const Color(0xFF0D9488),
            onTap: () => _confirmAndImportLoans(context),
          ),
        ],
        _QuickActionCard(
          icon: Icons.folder_shared_outlined,
          label: 'Closed Loans',
          color: AppTheme.textMuted,
          onTap: () => context.push('/admin/closed-loans'),
        ),
      ],
    );
  }

  static Future<void> _confirmAndImportLoans(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined,
                color: Color(0xFF0D9488), size: 22),
            SizedBox(width: 8),
            Text('Import 97 Legacy Loans'),
          ],
        ),
        content: const Text(
          'This will import all 97 customer and loan records from the verified CSV directly into your live database. Already imported loans will be safely skipped.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import Now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Importing 97 loans into database...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );

    try {
      final response =
          await ApiClient.instance.client.post('/admin/import-legacy-loans');
      final data = response.data['data'];
      final imported = data?['importedCount'] ?? 97;
      final skipped = data?['skippedCount'] ?? 0;

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successColor,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Successfully imported $imported loans ($skipped skipped)! Refreshing...'),
                ),
              ],
            ),
          ),
        );
        context.go('/admin/dashboard');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('Import failed: $e'),
          ),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveBounce(
      onTap: onTap,
      scaleFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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
    );
  }
}

