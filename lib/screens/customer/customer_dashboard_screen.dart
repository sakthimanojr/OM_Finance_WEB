import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(customerSummaryProvider);
    final user = ref.watch(authProvider).user;
    final displayName = user?.phone ?? 'Customer';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium Customer Header ───────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                tooltip: 'My Profile',
                onPressed: () => context.push('/customer/profile'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: GreetingHeader(
                name: displayName,
                subtitle: 'Your financial dashboard',
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.customerGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -35,
                      top: -25,
                      child: CircleAvatar(
                        radius: 85,
                        backgroundColor: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -25,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      top: 30,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    // Wallet emoji watermark
                    Positioned(
                      right: 24,
                      top: 24,
                      child: Text(
                        '💳',
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(customerSummaryProvider),
              child: summaryAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(customerSummaryProvider),
                ),
                data: (summary) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    // ── Outstanding hero card ──────────────────────────
                    Container(
                      decoration: AppTheme.customerHeroCardDecoration,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: AppTheme.glassmorphismCard(
                                    opacity: 0.15,
                                    borderOpacity: 0.2,
                                    radius: 12,
                                  ),
                                  child: const Text('💳',
                                      style: TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Total Outstanding Dues',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Formatters.currency(summary.totalOutstanding),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (summary.nextDueAmount != null)
                              _EmiReminderChip(
                                amount: summary.nextDueAmount,
                                date: summary.nextDueDate,
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: AppTheme.glassmorphismCard(
                                  opacity: 0.15,
                                  borderOpacity: 0.2,
                                  radius: 10,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white70, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'No pending dues — all caught up! 🎉',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Quick Links Row ───────────────────────────────
                    const _SectionTitle('Quick Actions'),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        EmojiIconButton(
                          emoji: '📋',
                          label: 'My Loans',
                          gradient: AppTheme.primaryGradient,
                          onTap: () => context.push('/customer/loans'),
                        ),
                        EmojiIconButton(
                          emoji: '🧾',
                          label: 'Payments',
                          gradient: AppTheme.accentGradient,
                          onTap: () => context.push('/customer/payments'),
                        ),
                        EmojiIconButton(
                          emoji: '🏦',
                          label: 'Chit Funds',
                          gradient: AppTheme.customerGradient,
                          onTap: () => context.push('/customer/chits'),
                        ),
                        EmojiIconButton(
                          emoji: '👤',
                          label: 'Profile',
                          gradient: AppTheme.darkGradient,
                          onTap: () => context.push('/customer/profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Account Summary Card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '📊 Account Summary',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark),
                              ),
                              Icon(Icons.badge_outlined,
                                  color: Colors.grey.shade400, size: 20),
                            ],
                          ),
                          const Divider(height: 24),
                          _StatRow(
                              'Total Principal Borrowed',
                              Formatters.currency(
                                  summary.totalPrincipalBorrowed)),
                          _StatRow(
                              'Total Principal Paid',
                              Formatters.currency(summary.totalPrincipalPaid),
                              valueColor: AppTheme.successColor),
                          _StatRow(
                              'Total Interest Paid',
                              Formatters.currency(summary.totalInterestPaid)),
                          _StatRow(
                              'Total Repaid To Date',
                              Formatters.currency(summary.totalAmountRepaid),
                              valueColor: AppTheme.primaryColor,
                              isBoldValue: true),
                          _StatRow('Total Active Loans',
                              '${summary.activeLoans}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Loan History ──────────────────────────────────
                    if (summary.loanHistory.isNotEmpty) ...[
                      const _SectionTitle('Active & Historical Loans'),
                      const SizedBox(height: 12),
                      ...summary.loanHistory.map(
                        (loan) => _LoanHistoryCard(loan: loan),
                      ),
                      const SizedBox(height: 8),
                    ],
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

// ── EMI Reminder Chip ────────────────────────────────────────────────────────

class _EmiReminderChip extends StatelessWidget {
  const _EmiReminderChip({required this.amount, required this.date});
  final dynamic amount;
  final dynamic date;

  int _daysUntil(dynamic dateStr) {
    if (dateStr == null) return 0;
    try {
      final d = DateTime.parse(dateStr.toString());
      return d.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(date);
    final urgency = days <= 2 ? '🔥' : (days <= 7 ? '⏳' : '📅');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppTheme.glassmorphismCard(
        opacity: 0.15,
        borderOpacity: 0.2,
        radius: 12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(urgency, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Next EMI: ${Formatters.currency(amount)} due ${days == 0 ? "today" : "in $days days"} (${Formatters.date(date)})',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loan History Card ────────────────────────────────────────────────────────

class _LoanHistoryCard extends StatelessWidget {
  const _LoanHistoryCard({required this.loan});
  final dynamic loan;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(loan.status);
    final emoji = AppTheme.statusEmoji(loan.status);

    // Compute repayment progress
    final principal = (loan.principal as num?)?.toDouble() ?? 1.0;
    final paid = (loan.totalCollection as num?)?.toDouble() ?? 0.0;
    final progress = principal > 0 ? (paid / (principal * 1.3)).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/customer/loans/${loan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.type.replaceAll('_', ' '),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${loan.loanNumber != null ? 'Loan #${loan.loanNumber} • ' : ''}${Formatters.currency(loan.principal)}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(loan.totalCollection),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: color.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          '$emoji ${loan.status}',
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Repayment progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repayment Progress',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 10),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value,
      {this.valueColor, this.isBoldValue = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBoldValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
