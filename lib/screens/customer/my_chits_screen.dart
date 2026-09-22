import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/chit_fund_model.dart';
import '../../providers/chit_fund_provider.dart';

class MyChitsScreen extends ConsumerWidget {
  const MyChitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myChitsAsync = ref.watch(myChitListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Header with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Chit Funds',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Dynamic abstract bubbles/shapes for premium aesthetics
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
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
              onRefresh: () async => ref.refresh(myChitListProvider),
              child: myChitsAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(myChitListProvider),
                ),
                data: (memberships) {
                  if (memberships.isEmpty) {
                    return const EmptyStateView(
                      message: 'You are not enrolled in any chit funds yet.',
                      icon: Icons.savings_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: memberships.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final m = memberships[index];
                      final chit = m.chit;
                      if (chit == null) return const SizedBox();
                      return _MyChitPremiumCard(member: m, chit: chit);
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

class _MyChitPremiumCard extends StatelessWidget {
  const _MyChitPremiumCard({required this.member, required this.chit});
  final ChitMember member;
  final ChitFund chit;


  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MyChitDetailScreen(chitId: chit.id),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance_rounded,
                          color: Colors.white, size: 20),
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
                          if (member.membershipLabel != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.group_outlined,
                                    size: 13, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Membership #${member.membershipLabel}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(status: chit.status, showIcon: true),
                  ],

                ),
                const SizedBox(height: 18),

                // Financial values with glassmorphic cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Premium',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(member.monthlyContribution),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fund Value',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(chit.regularAuctionAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progression Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: chit.memberCount > 0
                              ? chit.currentMonth / chit.memberCount
                              : 0,
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${chit.currentMonth}/${chit.memberCount} Months',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Won banner (if applicable)
                if (member.hasWonAuction) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successColor.withValues(alpha: 0.08),
                          AppTheme.primaryColor.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: AppTheme.successColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You won Auction #${member.wonAuctionNumber}',
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.successColor.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── My Chit Detail Screen ───────────────────────────────────────────────────

class MyChitDetailScreen extends ConsumerStatefulWidget {
  const MyChitDetailScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<MyChitDetailScreen> createState() => _MyChitDetailScreenState();
}

class _MyChitDetailScreenState extends ConsumerState<MyChitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(myChitDetailProvider(widget.chitId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: detailAsync.when(
          data: (m) => Text(
            m.chit?.name ?? 'Chit Details',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chit Detail'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Auctions'),
            Tab(text: 'Payments'),
            Tab(text: 'My Loans'),
          ],
        ),
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (membership) => TabBarView(
          controller: _tabController,
          children: [
            _MyAuctionsTab(chitId: widget.chitId),
            _MyPaymentsTab(chitId: widget.chitId),
            _MyLoansTab(chitId: widget.chitId),
          ],
        ),
      ),
    );
  }
}

// ─── My Auctions Tab ─────────────────────────────────────────────────────────

class _MyAuctionsTab extends ConsumerWidget {
  const _MyAuctionsTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(myChitAuctionsProvider(chitId));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myChitAuctionsProvider(chitId)),
      child: auctionsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (auctions) {
          if (auctions.isEmpty) {
            return const EmptyStateView(
              message: 'No auctions recorded yet.',
              icon: Icons.gavel_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: auctions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = auctions[index];
              final isRegular = a.auctionType == 'REGULAR';
              final isSettled = a.status == 'SETTLED';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isRegular ? AppTheme.primaryColor : Colors.purple)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Auction #${a.auctionNumber} • ${a.auctionType}',
                            style: TextStyle(
                              color: isRegular ? AppTheme.primaryColor : Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM yyyy').format(a.auctionDate),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Metrics Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AuctionMetric(
                          label: 'Auction Value',
                          value: Formatters.currency(a.auctionAmount),
                        ),
                        if (a.winningBid != null)
                          _AuctionMetric(
                            label: 'Winning Bid',
                            value: Formatters.currency(a.winningBid!),
                            valueColor: AppTheme.accentColor,
                          ),
                        if (a.winnerPayout != null)
                          _AuctionMetric(
                            label: 'Winner Payout',
                            value: Formatters.currency(a.winnerPayout!),
                            valueColor: AppTheme.successColor,
                          ),
                      ],
                    ),

                    if (isSettled && a.winnerName != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                            color: a.myWin == true ? AppTheme.successColor : Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.myWin == true ? 'You won this auction!' : 'Won by ${a.winnerName}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: a.myWin == true ? AppTheme.successColor : Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AuctionMetric extends StatelessWidget {
  const _AuctionMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textDark,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─── My Payments Tab ─────────────────────────────────────────────────────────

class _MyPaymentsTab extends ConsumerWidget {
  const _MyPaymentsTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myChitPaymentsProvider(chitId));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myChitPaymentsProvider(chitId)),
      child: paymentsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyStateView(
              message: 'No payment records found.',
              icon: Icons.payments_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = payments[index];
              final isPaid = p.status == 'PAID';
              final isPartial = p.status == 'PARTIAL';
              final statusColor = isPaid
                  ? AppTheme.successColor
                  : isPartial
                      ? AppTheme.accentColor
                      : AppTheme.errorColor;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Month #${p.monthNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Due Date: ${DateFormat('dd MMM yyyy').format(p.dueDate)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                          if (p.paidDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Paid: ${DateFormat('dd MMM yyyy').format(p.paidDate!)} via ${p.paymentMethod ?? ""}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(p.amountPaid),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── My Loans Tab ────────────────────────────────────────────────────────────

class _MyLoansTab extends ConsumerWidget {
  const _MyLoansTab({required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myChitLoansProvider(chitId));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myChitLoansProvider(chitId)),
      child: loansAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (loans) {
          if (loans.isEmpty) {
            return const EmptyStateView(
              message: 'No active loans or advances from this chit fund.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final l = loans[index];
              final isPaid = l.status == 'PAID';
              final isPartiallyPaid = l.status == 'PARTIALLY_PAID';
              final statusColor = isPaid
                  ? AppTheme.successColor
                  : l.status == 'ACTIVE'
                      ? Colors.blue
                      : isPartiallyPaid
                          ? AppTheme.accentColor
                          : AppTheme.errorColor;

              return GestureDetector(
                onTap: () => context.go('/customer/chits/$chitId/loans/${l.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                          const Icon(Icons.payments_outlined, color: Colors.blueGrey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.loanRef,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stats Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Principal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(Formatters.currency(l.principalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Interest', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(Formatters.currency(l.interestAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Remaining Due', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.currency(l.remainingAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: l.remainingAmount > 0 ? AppTheme.errorColor : AppTheme.successColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Due Date: ${DateFormat('dd MMM yyyy').format(l.dueDate)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

