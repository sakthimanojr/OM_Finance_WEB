import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/chit_fund_provider.dart';

class ChitFundReportsScreen extends ConsumerStatefulWidget {
  const ChitFundReportsScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<ChitFundReportsScreen> createState() => _ChitFundReportsScreenState();
}

class _ChitFundReportsScreenState extends ConsumerState<ChitFundReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chit Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Members'),
            Tab(text: 'Auctions'),
            Tab(text: 'Loans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(chitId: widget.chitId),
          _MemberReportTab(chitId: widget.chitId),
          _AuctionReportTab(chitId: widget.chitId),
          _LoanReportTab(chitId: widget.chitId),
        ],
      ),
    );
  }
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(chitSummaryReportProvider(chitId));
    return reportAsync.when(
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(message: err.toString()),
      data: (data) {
        final chit = data['chit'] as Map<String, dynamic>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(chit['name'] as String? ?? '', [
              _Stat('Status', chit['status'] as String? ?? ''),
              _Stat('Total Members', '${data['totalMembers']}'),
              _Stat('Unique Winners', '${data['uniqueWinners']}'),
              _Stat('Remaining Eligible', '${data['remainingEligible']}'),
            ]),
            const SizedBox(height: 12),
            _SummaryCard('Auction Stats', [
              _Stat('Regular Auctions', '${data['regularAuctions']}'),
              _Stat('Additional Auctions', '${data['additionalAuctions']}'),
              _Stat('Total Auctions', '${data['totalAuctions']}'),
            ]),
            const SizedBox(height: 12),
            _SummaryCard('Financial Summary', [
              _Stat('Accumulated Fund', Formatters.currency(data['accumulatedFund'] as num? ?? 0)),
              _Stat('Loans Outstanding', Formatters.currency(data['loansOutstanding'] as num? ?? 0)),
              _Stat('Interest Earned', Formatters.currency(data['interestEarned'] as num? ?? 0)),
              _Stat('Financier Balance', Formatters.currency(data['financierBalance'] as num? ?? 0),
                  bold: true, color: AppTheme.primaryColor),
            ]),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.title, this.stats);
  final String title;
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...stats.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.label, style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      s.value,
                      style: TextStyle(
                        fontWeight: s.bold ? FontWeight.bold : FontWeight.w600,
                        color: s.color ?? Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;
}

// ─── Member Report Tab ────────────────────────────────────────────────────────

class _MemberReportTab extends ConsumerWidget {
  const _MemberReportTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: ref.read(chitFundServiceProvider).getMemberReport(chitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString());
        final data = snapshot.data ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final m = data[i] as Map<String, dynamic>;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(m['customerName'] as String? ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (m['hasWonAuction'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Won #${m['wonAuctionNumber']}',
                                style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid: ${Formatters.currency(m['totalContributions'] as num? ?? 0)}',
                            style: const TextStyle(fontSize: 12)),
                        Text(
                          m['outstandingLoan'] != null && (m['outstandingLoan'] as num) > 0
                              ? 'Loan Due: ${Formatters.currency(m['outstandingLoan'] as num)}'
                              : 'No loan',
                          style: TextStyle(
                            fontSize: 12,
                            color: (m['outstandingLoan'] as num? ?? 0) > 0
                                ? AppTheme.errorColor
                                : Colors.green,
                          ),
                        ),
                        Text(
                          '${m['pendingPaymentsCount']} pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: (m['pendingPaymentsCount'] as int? ?? 0) > 0
                                ? AppTheme.accentColor
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Auction Report Tab ───────────────────────────────────────────────────────

class _AuctionReportTab extends ConsumerWidget {
  const _AuctionReportTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: ref.read(chitFundServiceProvider).getAuctionReport(chitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString());
        final data = snapshot.data ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final a = data[i] as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: a['type'] == 'REGULAR'
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.purple.withValues(alpha: 0.1),
                  child: Text('#${a['auctionNumber']}',
                      style: TextStyle(
                          color: a['type'] == 'REGULAR' ? AppTheme.primaryColor : Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                title: Text('${a['winner']}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Bid: ${Formatters.currency(a['winningBid'] as num? ?? 0)} • Month #${a['monthNumber']}'),
                trailing: Text(
                  Formatters.currency(a['winnerPayout'] as num? ?? 0),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                      fontSize: 13),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Loan Report Tab ──────────────────────────────────────────────────────────

class _LoanReportTab extends ConsumerWidget {
  const _LoanReportTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: ref.read(chitFundServiceProvider).getLoanReport(chitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString());
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const EmptyStateView(message: 'No loans to report', icon: Icons.receipt_long_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final l = data[i] as Map<String, dynamic>;
            final pctPaid = (l['totalRepayment'] as num?) != null && (l['totalRepayment'] as num) > 0
                ? ((l['amountPaid'] as num? ?? 0) / (l['totalRepayment'] as num)).clamp(0, 1).toDouble()
                : 0.0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l['memberName'] as String? ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Text(l['loanRef'] as String? ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pctPaid,
                      backgroundColor: Colors.grey.shade200,
                      color: l['status'] == 'PAID' ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${Formatters.currency(l['amountPaid'] as num? ?? 0)} / ${Formatters.currency(l['totalRepayment'] as num? ?? 0)}',
                            style: const TextStyle(fontSize: 11)),
                        Text('Remaining: ${Formatters.currency(l['remaining'] as num? ?? 0)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: (l['remaining'] as num? ?? 0) > 0
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
