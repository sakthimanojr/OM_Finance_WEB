import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/chit_loan_model.dart';
import '../../providers/chit_fund_provider.dart';

/// Customer-facing chit loan detail screen (spec item 24).
/// Shows principal, interest, repayment info, and repayment history.
/// User CANNOT edit any financial data — read-only view.
class MyChitLoanDetailScreen extends ConsumerWidget {
  const MyChitLoanDetailScreen({
    super.key,
    required this.chitId,
    required this.loanId,
  });

  final String chitId;
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(
      myChitLoanDetailProvider((chitId: chitId, loanId: loanId)),
    );

    return Scaffold(
      body: loanAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            title: const Text('Loan Details', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          body: ErrorView(message: err.toString()),
        ),
        data: (loan) => _LoanDetailBody(loan: loan),
      ),
    );
  }
}

class _LoanDetailBody extends StatelessWidget {
  const _LoanDetailBody({required this.loan});
  final ChitLoan loan;

  @override
  Widget build(BuildContext context) {
    final isPaid = loan.status == 'PAID';
    final isOverdue = loan.status == 'OVERDUE';
    final statusColor = isPaid
        ? AppTheme.successColor
        : isOverdue
            ? AppTheme.errorColor
            : loan.status == 'PARTIALLY_PAID'
                ? AppTheme.accentColor
                : Colors.blue;

    final progressPercent = loan.totalRepayment > 0
        ? (loan.amountPaid / loan.totalRepayment).clamp(0.0, 1.0)
        : 0.0;

    return CustomScrollView(
      slivers: [
        // ─── Premium Header ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              loan.loanRef,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                fontSize: 18,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loan.status.replaceAll('_', ' '),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.lock_outlined, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Read Only',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ─── Repayment Progress ────────────────────────────────────
                _SectionCard(
                  title: 'Repayment Progress',
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressPercent.toDouble(),
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(statusColor),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '${(progressPercent * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: progressPercent > 0.5
                                      ? Colors.white
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatColumn(
                            label: 'Total Repayment',
                            value: Formatters.currency(loan.totalRepayment),
                            color: AppTheme.textDark,
                          ),
                          _StatColumn(
                            label: 'Paid',
                            value: Formatters.currency(loan.amountPaid),
                            color: AppTheme.successColor,
                          ),
                          _StatColumn(
                            label: 'Remaining',
                            value: Formatters.currency(loan.remainingAmount),
                            color: loan.remainingAmount > 0
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Loan Details ──────────────────────────────────────────
                _SectionCard(
                  title: 'Loan Details',
                  child: Column(
                    children: [
                      _DetailRow('Principal Amount', Formatters.currency(loan.principalAmount)),
                      _DetailRow('Interest Rate', '${loan.interestRate}%'),
                      _DetailRow('Interest Amount', Formatters.currency(loan.interestAmount)),
                      _DetailRow(
                        'Total Repayment',
                        Formatters.currency(loan.totalRepayment),
                        bold: true,
                      ),
                      const Divider(height: 24),
                      _DetailRow('Loan Date', Formatters.date(loan.loanDate)),
                      _DetailRow('Due Date', Formatters.date(loan.dueDate)),
                      _DetailRow(
                        'Status',
                        loan.status.replaceAll('_', ' '),
                        valueColor: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Repayment History ─────────────────────────────────────
                _SectionCard(
                  title: 'Repayment History',
                  child: loan.transactions != null && loan.transactions!.isNotEmpty
                      ? Column(
                          children: loan.transactions!.asMap().entries.map((entry) {
                            final i = entry.key;
                            final tx = entry.value;
                            final isLast = i == loan.transactions!.length - 1;
                            return _RepaymentTimelineItem(
                              transaction: tx,
                              isLast: isLast,
                              index: i + 1,
                            );
                          }).toList(),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 36, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(
                                'No repayments recorded yet',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Detail Row ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.bold = false, this.valueColor});
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Column ─────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ─── Repayment Timeline Item ─────────────────────────────────────────────────

class _RepaymentTimelineItem extends StatelessWidget {
  const _RepaymentTimelineItem({
    required this.transaction,
    required this.isLast,
    required this.index,
  });
  final ChitLoanTransaction transaction;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.successColor.withOpacity(0.15),
                    border: Border.all(color: AppTheme.successColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Transaction content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.currency(transaction.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(transaction.transactionDate),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniTag(
                          'Principal: ${Formatters.currency(transaction.principalAmount)}',
                          Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        _MiniTag(
                          'Interest: ${Formatters.currency(transaction.interestAmount)}',
                          AppTheme.accentColor,
                        ),
                      ],
                    ),
                    if (transaction.paymentReference != null &&
                        transaction.paymentReference!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ref: ${transaction.paymentReference}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
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

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
