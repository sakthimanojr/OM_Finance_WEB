import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/chit_fund_provider.dart';

class ChitMonthlyAuctionScreen extends ConsumerStatefulWidget {
  const ChitMonthlyAuctionScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<ChitMonthlyAuctionScreen> createState() => _ChitMonthlyAuctionScreenState();
}

class _AuctionEntry {
  final TextEditingController auctionNumberCtrl;
  final TextEditingController winningBidCtrl;
  String auctionType;
  DateTime auctionDate;
  String? winnerId;

  _AuctionEntry({
    required int auctionNumber,
    required DateTime date,
  })  : auctionNumberCtrl = TextEditingController(text: '$auctionNumber'),
        winningBidCtrl = TextEditingController(),
        auctionType = 'REGULAR',
        auctionDate = date;

  void dispose() {
    auctionNumberCtrl.dispose();
    winningBidCtrl.dispose();
  }
}

class _ChitMonthlyAuctionScreenState extends ConsumerState<ChitMonthlyAuctionScreen> {
  String? _monthId;
  final List<_AuctionEntry> _entries = [];
  bool _loading = false;
  List<Map<String, dynamic>> _members = [];
  int _nextAuctionNumber = 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final months = await ref.read(chitFundServiceProvider).listMonths(widget.chitId);
      final openMonth = months.where((m) => m.status == 'OPEN').firstOrNull;
      final auctions = await ref.read(chitFundServiceProvider).listAuctions(widget.chitId);
      final members = await ref.read(chitFundServiceProvider).listMembers(widget.chitId);

      final eligibleMembers = members.where((m) => m.auctionEligible && m.status == 'ACTIVE').toList();

      setState(() {
        _monthId = openMonth?.id;
        _nextAuctionNumber = (auctions.map((a) => a.auctionNumber).fold(0, (prev, e) => e > prev ? e : prev)) + 1;
        _members = eligibleMembers
            .map((m) => {'id': m.id, 'name': m.displayName, 'phone': m.customerPhone ?? ''})
            .toList();
        _entries.add(_AuctionEntry(auctionNumber: _nextAuctionNumber, date: DateTime.now()));
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  void _addEntry() {
    setState(() {
      _nextAuctionNumber++;
      _entries.add(_AuctionEntry(auctionNumber: _nextAuctionNumber, date: DateTime.now()));
    });
  }

  void _removeEntry(int index) {
    _entries[index].dispose();
    setState(() => _entries.removeAt(index));
  }

  Future<void> _submit() async {
    if (_monthId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open month found. Open a month first.')),
      );
      return;
    }
    for (final e in _entries) {
      if (e.winnerId == null || (num.tryParse(e.winningBidCtrl.text) ?? -1) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All auctions need a winner and a valid winning bid')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final auctionList = _entries
          .map((e) => {
                'auctionNumber': int.parse(e.auctionNumberCtrl.text),
                'auctionType': e.auctionType,
                'auctionDate': e.auctionDate.toIso8601String(),
                'winnerId': e.winnerId!,
                'winningBid': num.parse(e.winningBidCtrl.text),
              })
          .toList();

      await ref.read(chitFundServiceProvider).createAuctions(widget.chitId, _monthId!, auctionList);

      ref.invalidate(chitAuctionListProvider(widget.chitId));
      ref.invalidate(chitFundDetailProvider(widget.chitId));
      ref.invalidate(chitFundSummaryProvider(widget.chitId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_entries.length} auction(s) recorded!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chitAsync = ref.watch(chitFundDetailProvider(widget.chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Record Auction(s)',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: chitAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (chit) => Column(
          children: [
            // ── Info banner (lime card) ──────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentLime.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.buttonBlack.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gavel, color: AppTheme.buttonBlack, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auction: ${Formatters.currency(chit.regularAuctionAmount)}  •  Min Bid: ${Formatters.currency(chit.startingBid)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '${_members.length} eligible member(s)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_monthId == null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No open month. Open a month in Monthly Payments.',
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == _entries.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: _addEntry,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Auction', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    );
                  }

                  final entry = _entries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.gavel, color: AppTheme.primaryColor, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Auction #',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  controller: entry.auctionNumberCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              DropdownButton<String>(
                                value: entry.auctionType,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                items: ['REGULAR', 'ADDITIONAL']
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => setState(() => entry.auctionType = v!),
                              ),
                              if (_entries.length > 1)
                                GestureDetector(
                                  onTap: () => _removeEntry(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.close,
                                        color: AppTheme.errorColor, size: 18),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Winner dropdown
                          DropdownButtonFormField<String>(
                            value: entry.winnerId,
                            hint: const Text('Select Winner'),
                            decoration: const InputDecoration(
                              labelText: 'Winner (eligible only)',
                              prefixIcon: Icon(Icons.emoji_events_outlined),
                            ),
                            items: _members
                                .map((m) => DropdownMenuItem<String>(
                                      value: m['id'] as String,
                                      child: Text('${m['name']} • ${m['phone']}'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => entry.winnerId = v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: entry.winningBidCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Winning Bid ₹',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Live payout calc
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.successColor.withOpacity(0.20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Winner Gets',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        () {
                                          final bid = num.tryParse(entry.winningBidCtrl.text) ?? 0;
                                          final payout = chit.regularAuctionAmount - bid;
                                          return Formatters.currency(payout > 0 ? payout : 0);
                                        }(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.successColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedGradientButton(
            onPressed: _loading || _entries.isEmpty || _monthId == null ? null : _submit,
            isLoading: _loading,
            icon: Icons.gavel,
            child: Text('Save ${_entries.length} Auction(s)'),
          ),
        ),
      ),
    );
  }
}
