import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/loan_provider.dart';

class CustomerLoanDetailScreen extends ConsumerWidget {
  const CustomerLoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailProvider(loanId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Loan Details', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: loanAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(loanDetailProvider(loanId)),
        ),
        data: (loan) => RefreshIndicator(
          onRefresh: () async => ref.refresh(loanDetailProvider(loanId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium loan header card
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.type.replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    if (loan.loanNumber != null)
                                      Text(
                                        'Loan #${loan.loanNumber}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  loan.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _WhiteStatCol('Principal',
                                  Formatters.currency(loan.principal)),
                              _WhiteStatCol('Total Paid',
                                  Formatters.currency(loan.totalCollection)),
                              _WhiteStatCol('Outstanding',
                                  Formatters.currency(loan.outstandingAmount)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loan breakdown card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Loan Breakdown',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.receipt_long_outlined,
                            color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                    const Divider(height: 24),
                    _DetailRow('Disbursed Amount',
                        Formatters.currency(loan.disbursedAmount)),
                    _DetailRow(
                        'Interest Rate', '${loan.interestRate}%',
                        valueColor: AppTheme.accentColor),
                    _DetailRow('Start Date', Formatters.date(loan.startDate)),
                    if (loan.endDate != null)
                      _DetailRow('End Date', Formatters.date(loan.endDate)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Due schedule header
              Row(
                children: [
                  const Text(
                    'Repayment Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${loan.dues.where((d) => d.status == 'PAID').length}/${loan.dues.length} paid',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: loan.dues.isEmpty
                      ? 0
                      : loan.dues
                              .where((d) => d.status == 'PAID')
                              .length /
                          loan.dues.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.successColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              ...loan.dues.map(
                (due) {
                  final isPaid = due.status == 'PAID';
                  final isOverdue = due.status == 'OVERDUE';
                  final borderColor = isPaid
                      ? AppTheme.successColor.withValues(alpha: 0.3)
                      : isOverdue
                          ? AppTheme.errorColor.withValues(alpha: 0.3)
                          : Colors.grey.shade100;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isPaid
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : isOverdue
                                ? AppTheme.errorColor.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                        child: Text(
                          '${due.dueNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppTheme.successColor
                                : isOverdue
                                    ? AppTheme.errorColor
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      title: Text(
                        Formatters.currency(due.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due ${Formatters.date(due.dueDate)}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                          if (due.status == 'PAID' && due.paidDate != null)
                            Text(
                              'Paid on ${Formatters.dateTime(due.paidDate!)}',
                              style: TextStyle(
                                  color: AppTheme.successColor, fontSize: 11),
                            ),
                        ],
                      ),
                      trailing: due.status == 'PAID'
                          ? const StatusBadge(status: 'PAID')
                          : Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(90, 36),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                ),
                                onPressed: () => context.push(
                                    '/customer/pay/${due.id}?amount=${due.amount}&dueNumber=${due.dueNumber}'),
                                child: const Text(
                                  'Pay Now',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteStatCol extends StatelessWidget {
  const _WhiteStatCol(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
