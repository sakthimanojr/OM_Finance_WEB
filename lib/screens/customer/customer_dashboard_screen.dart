import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/wave_container.dart';

import '../../core/widgets/interactive_card.dart';
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
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488), // Teal-green brand
        elevation: 0,
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
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 18),
            ),
            tooltip: 'My Profile',
            onPressed: () => context.push('/customer/profile'),
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
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        onRefresh: () async => ref.refresh(customerSummaryProvider),
        child: summaryAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(customerSummaryProvider),
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Top Greeting Card with Wave ────────────────────
              FadeSlideEntrance(
                delayIndex: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.customerGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.28),
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
                        subtitle: 'Your financial dashboard',
                        role: 'CUSTOMER',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Outstanding hero card with Animated Waves ───────
              FadeSlideEntrance(
                delayIndex: 1,
                child: Container(
                  decoration: AppTheme.customerHeroCardDecoration,
                  child: AnimatedWaveBackground(
                    waveOpacity1: 0.12,
                    waveOpacity2: 0.08,
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
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
                          if (summary.activeLoans == 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: AppTheme.glassmorphismCard(
                                opacity: 0.18,
                                borderOpacity: 0.25,
                                radius: 10,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GlowingPulseDot(
                                    color: Color(0xFF6EE7B7),
                                    size: 6,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'No Active Loan • Account Active',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (summary.nextDueAmount != null) ...[
                            _EmiReminderChip(
                              amount: summary.nextDueAmount,
                              date: summary.nextDueDate,
                            ),
                          ] else ...[
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
                                    'No pending dues — all caught up!',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick Links Row ───────────────────────────────
              FadeSlideEntrance(
                delayIndex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Quick Actions'),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActionIconButton(
                          icon: Icons.assignment_outlined,
                          label: 'My Loans',
                          gradient: AppTheme.primaryGradient,
                          onTap: () => context.push('/customer/loans'),
                        ),
                        ActionIconButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'Payments',
                          gradient: AppTheme.accentGradient,
                          onTap: () => context.push('/customer/payments'),
                        ),
                        ActionIconButton(
                          icon: Icons.account_balance_outlined,
                          label: 'Chit Funds',
                          gradient: AppTheme.customerGradient,
                          onTap: () => context.push('/customer/chits'),
                        ),
                        ActionIconButton(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          gradient: AppTheme.darkGradient,
                          onTap: () => context.push('/customer/profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Account Summary Card ──────────────────────────
              FadeSlideEntrance(
                delayIndex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded,
                                  color: AppTheme.primaryColor, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Account Summary',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GlowingPulseDot(
                                  color: Colors.green,
                                  size: 5,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Active Account',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          _StatRow('Active Loans',
                              summary.activeLoans > 0 ? '${summary.activeLoans}' : 'None (No Active Loan)'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),


                    // ── Loan History ──────────────────────────────────
                    if (summary.loanHistory.isNotEmpty) ...[
                      _SectionTitle(summary.activeLoans == 0
                          ? 'Loan History (All Loans Closed)'
                          : 'Active & Historical Loans'),
                      const SizedBox(height: 12),
                      if (summary.activeLoans == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No active loans. Your account remains active and all past loans are settled.',
                                  style: TextStyle(
                                    color: Color(0xFF0D9488),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...summary.loanHistory.map(
                        (loan) => _LoanHistoryCard(loan: loan),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      const _SectionTitle('Loan Status'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline, color: Color(0xFF0D9488), size: 36),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Active Loan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your account is active. When you take a new loan, its repayment schedule and details will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
    final (urgencyIcon, urgencyColor) = days <= 2
        ? (Icons.priority_high_rounded, const Color(0xFFF87171))
        : (days <= 7
            ? (Icons.schedule_rounded, const Color(0xFFFBBF24))
            : (Icons.calendar_today_rounded, Colors.white70));

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
          Icon(urgencyIcon, color: urgencyColor, size: 15),
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
    final statusIcon = AppTheme.statusIcon(loan.status);

    // Compute repayment progress
    final principal = (loan.principal as num?)?.toDouble() ?? 1.0;
    final paid = (loan.totalCollection as num?)?.toDouble() ?? 0.0;
    final progress =
        principal > 0 ? (paid / (principal * 1.3)).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InteractiveBounce(
        onTap: () => context.push('/customer/loans/${loan.id}'),
        scaleFactor: 0.98,
        child: Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: color, size: 18),
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
                      StatusBadge(status: loan.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade100,
                  color: color,
                  minHeight: 5,
                ),
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
