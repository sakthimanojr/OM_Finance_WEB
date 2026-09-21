import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/closed_loan_provider.dart';

class ClosedLoansScreen extends ConsumerStatefulWidget {
  const ClosedLoansScreen({super.key});

  @override
  ConsumerState<ClosedLoansScreen> createState() => _ClosedLoansScreenState();
}

class _ClosedLoansScreenState extends ConsumerState<ClosedLoansScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final closedLoansAsync = ref.watch(closedLoanListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Closed Loans Archive', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: closedLoansAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(closedLoanListProvider),
        ),
        data: (loans) {
          if (loans.isEmpty) {
            return const EmptyStateView(
              message: 'No closed loans found',
              icon: Icons.archive_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(closedLoanListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final loan = loans[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
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
                                color: AppTheme.successColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.archive_outlined, color: AppTheme.successColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                loan.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              Formatters.currency(loan.totalCollected),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.successColor, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(loan.customerPhone, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            if (loan.loanNumber != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.tag, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 2),
                              Text(loan.loanNumber!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 13, color: AppTheme.successColor),
                            const SizedBox(width: 4),
                            Text(
                              'Closed on ${dateFormat.format(loan.closedAt)}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
