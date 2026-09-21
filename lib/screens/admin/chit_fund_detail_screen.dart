import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chit_fund_provider.dart';

class ChitFundDetailScreen extends ConsumerWidget {
  const ChitFundDetailScreen({super.key, required this.chitId});
  final String chitId;

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppTheme.successColor;
      case 'COMPLETED':
        return AppTheme.primaryColor;
      case 'PAUSED':
        return AppTheme.warningColor;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chitAsync = ref.watch(chitFundDetailProvider(chitId));
    final fundAsync = ref.watch(chitFundSummaryProvider(chitId));
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: chitAsync.when(
          data: (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          loading: () => const Text('Chit Fund'),
          error: (_, __) => const Text('Chit Fund'),
        ),
        actions: [
          if (user?.isSuperAdmin == true)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'activate') {
                  try {
                    await ref
                        .read(chitFundServiceProvider)
                        .updateChitFund(chitId, {'status': 'ACTIVE'});
                    ref.invalidate(chitFundDetailProvider(chitId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chit fund activated successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Set Active'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chitFundDetailProvider(chitId));
          ref.invalidate(chitFundSummaryProvider(chitId));
        },
        child: chitAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorView(
              message: err.toString(), onRetry: () => ref.invalidate(chitFundDetailProvider(chitId))),
          data: (chit) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium Header card with metallic gradients
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withOpacity(0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.04),
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
                                child: Text(
                                  chit.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(chit.status).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(chit.status).withOpacity(0.6)),
                                ),
                                child: Text(
                                  chit.status,
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
                              _WhiteStatCol('Monthly Fee', Formatters.currency(chit.monthlyContribution)),
                              _WhiteStatCol('Regular Auction', Formatters.currency(chit.regularAuctionAmount)),
                              _WhiteStatCol('Current Month', '#${chit.currentMonth}'),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _WhiteStatCol('Members Count', '${chit.memberCount} enrolled'),
                              _WhiteStatCol('Completed Auctions', '${chit.completedAuctionCount} settled'),
                              _WhiteStatCol('Pending Auctions', '${chit.remainingWinners} left'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fund status cards with modern grid details
              fundAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
                data: (fund) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Capital Reserves Summary',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Icon(Icons.account_balance_outlined, color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _StatRow(
                        'Available Cash Balance',
                        Formatters.currency(fund['availableBalance'] as num? ?? 0),
                        valueColor: AppTheme.successColor,
                        isBoldValue: true,
                      ),
                      _StatRow(
                        'Outstanding Loan Principal',
                        Formatters.currency(fund['loansOutstanding'] as num? ?? 0),
                        valueColor: AppTheme.errorColor,
                        isBoldValue: true,
                      ),
                      _StatRow(
                        'Accrued Interest Receivable',
                        Formatters.currency(fund['interestReceivable'] as num? ?? 0),
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        'Available Capacity for Extra Auctions',
                        '${fund['additionalAuctionCapacity'] ?? 0} regular cycles possible',
                        valueColor: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Chit Management Tools',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _ToolsGridCard(
                    Icons.people_outline,
                    'Members',
                    Colors.teal,
                    () => context.push('/admin/chit-funds/$chitId/members'),
                  ),
                  _ToolsGridCard(
                    Icons.calendar_month_outlined,
                    'Payments',
                    Colors.orange,
                    () => context.push('/admin/chit-funds/$chitId/payments'),
                  ),
                  _ToolsGridCard(
                    Icons.gavel_outlined,
                    'Auctions',
                    Colors.purple,
                    () => context.push('/admin/chit-funds/$chitId/auctions'),
                  ),
                  _ToolsGridCard(
                    Icons.account_balance_wallet_outlined,
                    'Ledger Logs',
                    Colors.blue,
                    () => context.push('/admin/chit-funds/$chitId/fund'),
                  ),
                  _ToolsGridCard(
                    Icons.receipt_long_outlined,
                    'Advances/Loans',
                    Colors.indigo,
                    () => context.push('/admin/chit-funds/$chitId/loans'),
                  ),
                  _ToolsGridCard(
                    Icons.bar_chart_outlined,
                    'Chit Reports',
                    Colors.pink,
                    () => context.push('/admin/chit-funds/$chitId/reports'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Members List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled Members (${chit.membersList?.length ?? 0})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/admin/chit-funds/$chitId/members'),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Manage', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (chit.membersList != null)
                ...chit.membersList!.map((m) {
                  final statusColor = m.hasWonAuction ? AppTheme.successColor : AppTheme.primaryColor;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Text(
                          m.customerName?.isNotEmpty == true
                              ? m.customerName![0].toUpperCase()
                              : '?',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(m.customerPhone ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      trailing: m.hasWonAuction
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Won Auction #${m.wonAuctionNumber}',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Eligible Winner',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: chitAsync.when(
        data: (chit) => chit.status == 'ACTIVE'
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/admin/chit-funds/$chitId/auctions/new'),
                icon: const Icon(Icons.gavel),
                label: const Text('Record Auction'),
                backgroundColor: AppTheme.accentColor,
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
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
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value, {this.valueColor, this.isBoldValue = false});
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

class _ToolsGridCard extends StatelessWidget {
  const _ToolsGridCard(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
