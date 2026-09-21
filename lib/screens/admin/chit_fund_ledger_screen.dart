import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/chit_fund_provider.dart';

class ChitFundLedgerScreen extends ConsumerWidget {
  const ChitFundLedgerScreen({super.key, required this.chitId});
  final String chitId;

  Color _txColor(String type, String direction) {
    return direction == 'CREDIT' ? AppTheme.successColor : AppTheme.errorColor;
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'WINNING_BID_CREDIT':
        return Icons.gavel;
      case 'LOAN_DISBURSEMENT':
        return Icons.arrow_upward;
      case 'LOAN_PRINCIPAL_REPAYMENT':
        return Icons.arrow_downward;
      case 'LOAN_INTEREST_CREDIT':
        return Icons.percent;
      case 'ADDITIONAL_AUCTION_ALLOCATION':
        return Icons.add_circle_outline;
      default:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(chitLedgerProvider(chitId));
    final fundAsync = ref.watch(chitFundSummaryProvider(chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Fund Ledger', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Balance summary
          fundAsync.when(
            loading: () => const LinearProgressIndicator(color: AppTheme.primaryColor),
            error: (_, __) => const SizedBox(),
            data: (fund) => Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      'Available',
                      Formatters.currency(fund['availableBalance'] as num? ?? 0),
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceCard(
                      'Loans Out',
                      Formatters.currency(fund['loansOutstanding'] as num? ?? 0),
                      AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceCard(
                      'Extra Auctions',
                      '${fund['additionalAuctionCapacity'] ?? 0}',
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ledger list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(chitLedgerProvider(chitId)),
              child: ledgerAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(chitLedgerProvider(chitId)),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const EmptyStateView(
                      message: 'No ledger entries yet.\nAuctions and loans will appear here.',
                      icon: Icons.account_balance_outlined,
                    );
                  }
                  // Show in reverse chronological order
                  final reversed = entries.reversed.toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: reversed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final entry = reversed[index];
                      final isCredit = entry.direction == 'CREDIT';
                      final color = _txColor(entry.transactionType, entry.direction);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_txIcon(entry.transactionType), color: color, size: 18),
                            ),
                            title: Text(
                              entry.description,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                            subtitle: Text(
                              '${DateFormat('dd MMM yy, hh:mm a').format(entry.createdAt)} · Bal: ${Formatters.currency(entry.balanceAfter)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${isCredit ? '+' : '-'}${Formatters.currency(entry.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style:
                  TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
