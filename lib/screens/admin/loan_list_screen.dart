import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/interactive_card.dart';
import '../../providers/loan_provider.dart';


class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key, this.status});
  final String? status;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanStatusFilterProvider.notifier).state = widget.status;
    });
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppTheme.primaryColor;
      case 'OVERDUE':
      case 'DEFAULTED':
        return AppTheme.errorColor;
      case 'COMPLETED':
        return AppTheme.successColor;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(adminLoanListProvider);
    final currentFilter = ref.watch(loanStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          currentFilter == 'ACTIVE' ? 'Active Loans' : 'All Loans',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Premium filter chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: currentFilter == null,
                    onTap: () => ref.read(loanStatusFilterProvider.notifier).state = null,
                  ),
                  ...['ACTIVE', 'OVERDUE', 'COMPLETED'].map(
                    (status) => _FilterChip(
                      label: status,
                      isSelected: currentFilter == status,
                      color: _statusColor(status),
                      onTap: () => ref.read(loanStatusFilterProvider.notifier).state = status,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: loansAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(adminLoanListProvider),
              ),
              data: (loans) {
                if (loans.isEmpty) {
                  return const EmptyStateView(
                    message: 'No loans found',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminLoanListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      final sColor = _statusColor(loan.status);
                      return FadeSlideEntrance(
                        delayIndex: index.clamp(0, 10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InteractiveBounce(
                            onTap: () => context.push('/admin/loans/${loan.id}'),
                            scaleFactor: 0.98,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: sColor.withValues(alpha: 0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: sColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          AppTheme.statusIcon(loan.status),
                                          color: sColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${loan.type.replaceAll('_', ' ')} • ${Formatters.currency(loan.principal)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Loan #${loan.loanNumber ?? 'N/A'} • ${loan.customerName ?? 'N/A'}',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(
                                          status: loan.status,
                                          showIcon: true),
                                    ],
                                  ),

                                const SizedBox(height: 10),
                                // Repayment progress bar
                                Builder(builder: (ctx) {
                                  final principal =
                                      (loan.principal as num?)?.toDouble() ??
                                          1.0;
                                  final collected =
                                      (loan.totalCollection as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final progress = principal > 0
                                      ? (collected / (principal * 1.3))
                                          .clamp(0.0, 1.0)
                                      : 0.0;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Repayment Progress',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 10),
                                          ),
                                          Text(
                                            '${(progress * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              color: sColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 5,
                                          backgroundColor:
                                              Colors.grey.shade100,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  sColor),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  );
                                }),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 12,
                                        color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Started: ${Formatters.date(loan.startDate)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? chipColor : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
