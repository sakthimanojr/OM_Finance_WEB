import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/chit_fund_model.dart';
import '../../providers/chit_fund_provider.dart';

class ChitFundListScreen extends ConsumerWidget {
  const ChitFundListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chitsAsync = ref.watch(chitFundListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chit Funds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Chit Fund',
            onPressed: () async {
              await context.push('/admin/chit-funds/new');
              ref.refresh(chitFundListProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(chitFundListProvider),
        child: chitsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.refresh(chitFundListProvider)),
          data: (chits) {
            if (chits.isEmpty) {
              return const EmptyStateView(
                message: 'No chit funds yet.\nTap + to create one.',
                icon: Icons.savings_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chits.length,
              itemBuilder: (context, index) =>
                  _ChitFundCard(chit: chits[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ChitFundCard extends StatelessWidget {
  const _ChitFundCard({required this.chit});
  final ChitFund chit;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppTheme.successColor;
      case 'COMPLETED':
        return Colors.blue;
      case 'PAUSED':
        return AppTheme.accentColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _statusColor(chit.status);
    final isCompleted = chit.status.toUpperCase() == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/admin/chit-funds/${chit.id}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Circle indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.savings_outlined,
                          color: sColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chit.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Micro tags wrap
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _MicroTag(
                                    Icons.people_outline,
                                    '${chit.memberCount} members',
                                    Colors.grey.shade600),
                                _MicroTag(
                                    Icons.calendar_month_outlined,
                                    'Month ${chit.currentMonth}',
                                    Colors.grey.shade600),
                                _MicroTag(
                                    Icons.gavel_outlined,
                                    '${chit.completedAuctionCount} auctions',
                                    Colors.grey.shade600),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      StatusBadge(status: chit.status),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F3F5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Contribution',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(chit.monthlyContribution),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Regular Auction Amount',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(chit.regularAuctionAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isCompleted
                                  ? Colors.grey.shade700
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicroTag extends StatelessWidget {
  const _MicroTag(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
