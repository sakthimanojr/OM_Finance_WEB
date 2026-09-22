import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/chit_fund_provider.dart';

class ChitLoansScreen extends ConsumerWidget {
  const ChitLoansScreen({super.key, required this.chitId});
  final String chitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(chitLoanListProvider(chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Chit Loans',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Member loan records',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: true,
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async => ref.refresh(chitLoanListProvider(chitId)),
              child: loansAsync.when(
                loading: () => const LoadingView(),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(chitLoanListProvider(chitId)),
                ),
                data: (loans) {
                  if (loans.isEmpty) {
                    return const EmptyStateView(
                      message: 'No loans yet.',
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final l = loans[index];
                      return _ChitLoanCard(
                        loan: l,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChitLoanDetailScreen(
                              loanId: l.id,
                              chitId: chitId,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => CreateChitLoanScreen(chitId: chitId)),
          );
          if (result == true) ref.invalidate(chitLoanListProvider(chitId));
        },
        icon: const Icon(Icons.add),
        label: const Text('New Loan', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

// ── Chit Loan Card ─────────────────────────────────────────────────────────────

class _ChitLoanCard extends StatefulWidget {
  const _ChitLoanCard({required this.loan, required this.onTap});
  final dynamic loan;
  final VoidCallback onTap;

  @override
  State<_ChitLoanCard> createState() => _ChitLoanCardState();
}

class _ChitLoanCardState extends State<_ChitLoanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.loan;
    final remaining = l.remainingAmount as num;
    final total = l.totalRepayment as num;
    final paid = l.amountPaid as num;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final remainingColor = remaining > 0 ? AppTheme.errorColor : AppTheme.successColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
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
                // Header row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (l.memberName as String? ?? '?').isNotEmpty
                              ? (l.memberName as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.memberName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Ref: ${l.loanRef}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: l.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(
                      label: 'Principal',
                      value: Formatters.currency(l.principalAmount),
                      color: AppTheme.primaryColor,
                    ),
                    _StatChip(
                      label: 'Interest (${l.interestRate}%)',
                      value: Formatters.currency(l.interestAmount),
                      color: AppTheme.warningColor,
                    ),
                    _StatChip(
                      label: 'Remaining',
                      value: Formatters.currency(remaining),
                      color: remainingColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
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
                const SizedBox(height: 8),

                // Due date + paid label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(l.dueDate)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% paid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
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
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─── Create Loan Screen ──────────────────────────────────────────────────────


class CreateChitLoanScreen extends ConsumerStatefulWidget {
  const CreateChitLoanScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<CreateChitLoanScreen> createState() => _CreateChitLoanScreenState();
}

class _CreateChitLoanScreenState extends ConsumerState<CreateChitLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController();
  String? _memberId;
  DateTime _loanDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;
  num _availableBalance = 0;
  num _interestRate = 3;

  num get _autoInterest {
    final p = num.tryParse(_principalCtrl.text) ?? 0;
    return (p * _interestRate / 100 * 100).round() / 100;
  }

  num get _totalRepayment {
    final p = num.tryParse(_principalCtrl.text) ?? 0;
    return p + _autoInterest;
  }

  @override
  void initState() {
    super.initState();
    _loadFund();
  }

  Future<void> _loadFund() async {
    try {
      final fund = await ref.read(chitFundServiceProvider).getFundSummary(widget.chitId);
      final chit = await ref.read(chitFundServiceProvider).getChitFund(widget.chitId);
      setState(() {
        _availableBalance = (fund['availableBalance'] as num? ?? 0);
        _interestRate = chit.interestRate;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_memberId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a member')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(chitFundServiceProvider).createLoan(
            chitId: widget.chitId,
            memberId: _memberId!,
            principalAmount: num.parse(_principalCtrl.text),
            loanDate: _loanDate,
            dueDate: _dueDate,
          );
      if (mounted) Navigator.of(context).pop(true);
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
    final membersAsync = ref.watch(chitMemberListProvider(widget.chitId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(title: const Text('Create Chit Loan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Balance Card (lime accent) ───────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _availableBalance > 0 ? AppTheme.accentLime : AppTheme.errorColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_availableBalance > 0 ? AppTheme.accentLime : AppTheme.errorColor)
                        .withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.buttonBlack.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: _availableBalance > 0 ? AppTheme.buttonBlack : AppTheme.errorColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Fund',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        Formatters.currency(_availableBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _availableBalance > 0 ? AppTheme.textDark : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section label ────────────────────────────────────────
            const Text(
              'Loan Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 12),

            // Member selector
            membersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Could not load members'),
              data: (members) {
                final active = members.where((m) => m.status == 'ACTIVE').toList();
                return DropdownButtonFormField<String>(
                  value: _memberId,
                  hint: const Text('Select Member'),
                  decoration: const InputDecoration(
                    labelText: 'Member *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: active
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _memberId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _principalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Principal Amount ₹ *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Must be positive';
                if (n > _availableBalance) return 'Exceeds available balance';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Auto-calculated interest card ────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interest ($_interestRate% flat)',
                        style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      Text(
                        Formatters.currency(_autoInterest),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 14),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade100, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Repayment',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 14),
                      ),
                      Text(
                        Formatters.currency(_totalRepayment),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Date pickers ─────────────────────────────────────────
            Container(
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 18),
                    ),
                    title: const Text('Loan Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_loanDate),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _loanDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) setState(() => _loanDate = picked);
                    },
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ),
                  Divider(color: Colors.grey.shade100, height: 1, indent: 18),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_available_outlined, color: AppTheme.errorColor, size: 18),
                    ),
                    title: const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: _loanDate,
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AnimatedGradientButton(
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
              gradient: AppTheme.primaryGradient,
              icon: Icons.add_card_outlined,
              child: const Text('Create Loan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loan Detail Screen ──────────────────────────────────────────────────────

class ChitLoanDetailScreen extends ConsumerStatefulWidget {
  const ChitLoanDetailScreen({super.key, required this.loanId, required this.chitId});
  final String loanId;
  final String chitId;

  @override
  ConsumerState<ChitLoanDetailScreen> createState() => _ChitLoanDetailScreenState();
}

class _ChitLoanDetailScreenState extends ConsumerState<ChitLoanDetailScreen> {
  Future<void> _showRepayDialog(BuildContext context) async {
    final loan = await ref.read(chitFundServiceProvider).getLoan(widget.loanId);
    final remaining = loan.remainingAmount;
    final principal = loan.principalAmount;
    final interest = loan.interestAmount;
    final paid = loan.amountPaid;

    final principalRemaining = (principal - (paid > interest ? paid - interest : paid)).clamp(0, principal);
    final interestRemaining = (interest - (paid > principalRemaining ? paid - principalRemaining : 0)).clamp(0, interest);

    final pCtrl = TextEditingController(text: principalRemaining.toStringAsFixed(2));
    final iCtrl = TextEditingController(text: interestRemaining.toStringAsFixed(2));
    final refCtrl = TextEditingController();
    String method = 'CASH';
    DateTime paidDate = DateTime.now();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Repay Loan – ${loan.loanRef}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Remaining: ${Formatters.currency(remaining)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: pCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Principal ₹'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: iCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Interest ₹'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference (optional)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['CASH', 'UPI', 'BANK_TRANSFER', 'MANUAL']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setDlg(() => method = v!),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: paidDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    helpText: 'Select Repayment Date',
                  );
                  if (picked != null) setDlg(() => paidDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Paid Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(paidDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(chitFundServiceProvider).repayLoan(
                        loanId: widget.loanId,
                        principalAmount: num.tryParse(pCtrl.text) ?? 0,
                        interestAmount: num.tryParse(iCtrl.text) ?? 0,
                        paymentReference: refCtrl.text.isEmpty ? null : refCtrl.text,
                        paymentMethod: method,
                        transactionDate: paidDate,
                      );
                  ref.invalidate(chitLoanListProvider(widget.chitId));
                  ref.invalidate(chitFundSummaryProvider(widget.chitId));
                  ref.invalidate(chitLedgerProvider(widget.chitId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Repayment recorded!')));
                    Navigator.of(context).pop();
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
    final loanAsync = ref.watch(chitLoanDetailProvider(widget.loanId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(title: const Text('Loan Details')),
      body: loanAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (loan) => RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async => ref.refresh(chitLoanDetailProvider(widget.loanId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Gradient hero card ───────────────────────────────
              Container(
                decoration: AppTheme.heroCardDecoration,
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.memberName ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loan.loanRef,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  loan.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _WhiteStatCol('Principal', Formatters.currency(loan.principalAmount)),
                              _WhiteStatCol('Interest (${loan.interestRate}%)', Formatters.currency(loan.interestAmount)),
                              _WhiteStatCol('Total', Formatters.currency(loan.totalRepayment)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: loan.totalRepayment > 0
                                  ? (loan.amountPaid / loan.totalRepayment).clamp(0, 1).toDouble()
                                  : 0,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Paid: ${Formatters.currency(loan.amountPaid)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Remaining: ${Formatters.currency(loan.remainingAmount)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Date info card ───────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: AppTheme.cardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.primaryColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loan: ${DateFormat('dd MMM yyyy').format(loan.loanDate)}  →  Due: ${DateFormat('dd MMM yyyy').format(loan.dueDate)}',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Repayment history ────────────────────────────────
              const Text(
                'Repayment History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 12),
              if (loan.transactions == null || loan.transactions!.isEmpty)
                const EmptyStateView(
                  message: 'No repayments yet',
                  icon: Icons.receipt_long_outlined,
                ),
              ...?loan.transactions?.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_downward,
                            color: AppTheme.successColor, size: 18),
                      ),
                      title: Text(
                        Formatters.currency(t.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'P: ${Formatters.currency(t.principalAmount)} + I: ${Formatters.currency(t.interestAmount)}'
                        '${t.paymentReference != null ? '\nRef: ${t.paymentReference}' : ''}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('dd MMM yy').format(t.transactionDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
      floatingActionButton: loanAsync.when(
        data: (loan) => loan.status != 'PAID'
            ? FloatingActionButton.extended(
                onPressed: () => _showRepayDialog(context),
                icon: const Icon(Icons.payment),
                label: const Text('Record Repayment', style: TextStyle(fontWeight: FontWeight.w700)),
                backgroundColor: AppTheme.successColor,
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}

class _WhiteStatCol extends StatelessWidget {
  const _WhiteStatCol(this.l, this.v);
  final String l;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}
