import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/chit_fund_provider.dart';

class ChitAuctionHistoryScreen extends ConsumerWidget {
  const ChitAuctionHistoryScreen({super.key, required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(chitAuctionListProvider(chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Auction History', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(chitAuctionListProvider(chitId)),
        child: auctionsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) =>
              ErrorView(message: err.toString(), onRetry: () => ref.refresh(chitAuctionListProvider(chitId))),
          data: (auctions) {
            if (auctions.isEmpty) {
              return const EmptyStateView(
                  message: 'No auctions recorded yet.', icon: Icons.gavel);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: auctions.length,
              itemBuilder: (context, index) {
                final a = auctions[index];
                final isRegular = a.auctionType == 'REGULAR';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isRegular ? AppTheme.primaryColor : AppTheme.warningColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (isRegular ? AppTheme.primaryColor : AppTheme.warningColor).withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              'Auction #${a.auctionNumber} · ${a.auctionType}',
                              style: TextStyle(
                                color: isRegular ? AppTheme.primaryColor : AppTheme.warningColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy').format(a.auctionDate),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ACol('Auction Amt', Formatters.currency(a.auctionAmount)),
                          _ACol('Winning Bid',
                              a.winningBid != null ? Formatters.currency(a.winningBid!) : '-',
                              color: AppTheme.accentColor),
                          _ACol('Winner Payout',
                              a.winnerPayout != null ? Formatters.currency(a.winnerPayout!) : '-',
                              color: AppTheme.successColor),
                        ],
                      ),
                      if (a.winnerName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined,
                                size: 16, color: AppTheme.accentColor),
                            const SizedBox(width: 4),
                            Text(a.winnerName!,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (a.payoutStatus != null)
                              _PayoutBadge(a.payoutStatus!,
                                  auctionId: a.id, chitId: chitId, ref: ref),
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
      ),
    );
  }
}

class _ACol extends StatelessWidget {
  const _ACol(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
                fontSize: 14)),
      ],
    );
  }
}

class _PayoutBadge extends StatefulWidget {
  const _PayoutBadge(this.status, {required this.auctionId, required this.chitId, required this.ref});
  final String status;
  final String auctionId;
  final String chitId;
  final WidgetRef ref;

  @override
  State<_PayoutBadge> createState() => _PayoutBadgeState();
}

class _PayoutBadgeState extends State<_PayoutBadge> {
  bool _marking = false;

  @override
  Widget build(BuildContext context) {
    if (widget.status == 'PAID') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Payout Paid',
            style: TextStyle(
                color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    return _marking
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : GestureDetector(
            onTap: () async {
              setState(() => _marking = true);
              try {
                await widget.ref.read(chitFundServiceProvider).markPayoutPaid(widget.auctionId);
                widget.ref.refresh(chitAuctionListProvider(widget.chitId));
              } catch (_) {}
              if (mounted) setState(() => _marking = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Mark Paid',
                  style: TextStyle(
                      color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          );
  }
}
