import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/chit_fund_provider.dart';

class ChitMonthlyPaymentsScreen extends ConsumerStatefulWidget {
  const ChitMonthlyPaymentsScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<ChitMonthlyPaymentsScreen> createState() => _ChitMonthlyPaymentsScreenState();
}

class _ChitMonthlyPaymentsScreenState extends ConsumerState<ChitMonthlyPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMonthId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showRecordPaymentDialog(BuildContext context, String memberId, String memberName) async {
    final amtCtrl = TextEditingController();
    String method = 'CASH';
    final formKey = GlobalKey<FormState>();

    final months = await ref.read(chitFundServiceProvider).listMonths(widget.chitId);
    final openMonths = months.where((m) => m.status == 'OPEN').toList();

    if (!context.mounted) return;
    if (openMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open months. Open a month first.')),
      );
      return;
    }

    String monthId = _selectedMonthId ?? openMonths.last.id;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Record Payment – $memberName'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: monthId,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: openMonths
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                                'Month #${m.monthNumber} – ${DateFormat('MMM yyyy').format(m.periodStart)}'),
                          ))
                      .toList(),
                  onChanged: (v) => setDlgState(() => monthId = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid ₹',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) => (num.tryParse(v ?? '') ?? 0) > 0 ? null : 'Required',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: ['CASH', 'UPI', 'BANK_TRANSFER', 'MANUAL']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => method = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(chitFundServiceProvider).recordPayment(
                        chitId: widget.chitId,
                        memberId: memberId,
                        monthId: monthId,
                        amountPaid: num.parse(amtCtrl.text),
                        paymentMethod: method,
                      );
                  ref.invalidate(chitPaymentListProvider(widget.chitId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(chitPaymentListProvider(widget.chitId));
    final monthsAsync = ref.watch(chitMonthListProvider(widget.chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Monthly Payments',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentLime,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'All Payments'),
            Tab(text: 'Months'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Payment list ──────────────────────────────────
          paymentsAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.refresh(chitPaymentListProvider(widget.chitId)),
            ),
            data: (payments) => payments.isEmpty
                ? const EmptyStateView(
                    message: 'No payments recorded yet.',
                    icon: Icons.payments_outlined,
                  )
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: () async => ref.refresh(chitPaymentListProvider(widget.chitId)),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: payments.length,
                      itemBuilder: (context, i) {
                        final p = payments[i];
                        return _PaymentCard(payment: p);
                      },
                    ),
                  ),
          ),

          // ── Tab 2: Months ────────────────────────────────────────
          monthsAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => ErrorView(message: err.toString()),
            data: (months) => months.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const EmptyStateView(
                        message: 'No months yet.',
                        icon: Icons.calendar_month_outlined,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openNewMonthDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Open Month'),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    itemCount: months.length + 1,
                    itemBuilder: (context, i) {
                      if (i == months.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => _openNewMonthDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Open Next Month'),
                          ),
                        );
                      }
                      final m = months[i];
                      return _MonthCard(
                        month: m,
                        onClose: m.status == 'OPEN' ? () => _closeMonth(m.id) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickPaymentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _openNewMonthDialog(BuildContext context) async {
    final months = await ref.read(chitFundServiceProvider).listMonths(widget.chitId);
    final nextStart = months.isNotEmpty
        ? DateTime(months.last.periodStart.year, months.last.periodStart.month + 1, 1)
        : DateTime.now();

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open New Month'),
        content: Text('Open Month for ${DateFormat('MMMM yyyy').format(nextStart)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(chitFundServiceProvider).createMonth(widget.chitId, nextStart);
      ref.invalidate(chitMonthListProvider(widget.chitId));
      ref.invalidate(chitPaymentListProvider(widget.chitId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Month opened!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _closeMonth(String monthId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Month?'),
        content: const Text(
            'All auctions must be settled before closing. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Close Month'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(chitFundServiceProvider).closeMonth(widget.chitId, monthId);
      ref.invalidate(chitMonthListProvider(widget.chitId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Month closed!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _showQuickPaymentDialog(BuildContext context) async {
    final members = await ref.read(chitFundServiceProvider).listMembers(widget.chitId);
    if (members.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No members found')));
      }
      return;
    }
    if (!context.mounted) return;
    await _showRecordPaymentDialog(context, members.first.id, members.first.displayName);
  }
}

// ── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final dynamic payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final statusColor = p.status == 'PAID'
        ? AppTheme.successColor
        : p.status == 'PARTIAL'
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.10), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.10),
          child: Text(
            (p.memberName as String? ?? '?').isNotEmpty
                ? (p.memberName as String)[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          p.memberName ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          'Month #${p.monthNumber} • ${p.paymentMethod ?? ''}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(p.amountPaid),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            StatusBadge(status: p.status),
          ],
        ),
      ),
    );
  }
}

// ── Month Card ────────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, this.onClose});
  final dynamic month;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final m = month;
    final isOpen = m.status == 'OPEN';
    final collected = m.amountCollected as num;
    final due = m.amountDue as num;
    final progress = due > 0 ? (collected / due).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isOpen ? AppTheme.primaryColor : AppTheme.successColor)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${m.monthNumber}',
                    style: TextStyle(
                      color: isOpen ? AppTheme.primaryColor : AppTheme.successColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month #${m.monthNumber} – ${DateFormat('MMM yyyy').format(m.periodStart)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Collected: ${Formatters.currency(collected)} / ${Formatters.currency(due)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isOpen && onClose != null)
                  OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  )
                else if (!isOpen)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: AppTheme.successColor, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
