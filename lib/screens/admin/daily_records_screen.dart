import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../services/daily_record_service.dart';

class DailyRecordsScreen extends StatefulWidget {
  const DailyRecordsScreen({super.key});

  @override
  State<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends State<DailyRecordsScreen> {
  final DailyRecordService _service = DailyRecordService();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _record;

  // Editable controllers
  final _openingBalanceCtrl = TextEditingController();
  final _otherIncome1LabelCtrl = TextEditingController();
  final _otherIncome1Ctrl = TextEditingController();
  final _otherIncome2LabelCtrl = TextEditingController();
  final _otherIncome2Ctrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  @override
  void dispose() {
    _openingBalanceCtrl.dispose();
    _otherIncome1LabelCtrl.dispose();
    _otherIncome1Ctrl.dispose();
    _otherIncome2LabelCtrl.dispose();
    _otherIncome2Ctrl.dispose();
    _expensesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadRecord() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getRecord(_dateKey(_selectedDate));
      _populateControllers(data);
      setState(() {
        _record = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _openingBalanceCtrl.text =
        (data['openingBalance'] as num? ?? 0).toStringAsFixed(2);
    _otherIncome1LabelCtrl.text = data['otherIncome1Label'] as String? ?? '';
    _otherIncome1Ctrl.text =
        (data['otherIncome1Amount'] as num? ?? 0).toStringAsFixed(2);
    _otherIncome2LabelCtrl.text = data['otherIncome2Label'] as String? ?? '';
    _otherIncome2Ctrl.text =
        (data['otherIncome2Amount'] as num? ?? 0).toStringAsFixed(2);
    _expensesCtrl.text =
        (data['expenses'] as num? ?? 0).toStringAsFixed(2);
    _notesCtrl.text = data['notes'] as String? ?? '';
  }

  /// Computes the live closing balance from current form inputs + auto-computed fields
  double _computeClosingBalance() {
    final opening = double.tryParse(_openingBalanceCtrl.text) ?? 0;
    final billIncome =
        (_record?['autoBillIncome'] as num? ?? 0).toDouble();
    final loanIncome =
        (_record?['loansGivenIncome'] as num? ?? 0).toDouble();
    final loanPrincipal =
        (_record?['loansGivenPrincipal'] as num? ?? 0).toDouble();
    final otherIncome1 = double.tryParse(_otherIncome1Ctrl.text) ?? 0;
    final otherIncome2 = double.tryParse(_otherIncome2Ctrl.text) ?? 0;
    final expenses = double.tryParse(_expensesCtrl.text) ?? 0;

    return opening +
        billIncome +
        loanIncome +
        otherIncome1 +
        otherIncome2 -
        loanPrincipal -
        expenses;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final record = _record;
      await _service.saveRecord({
        'date': _dateKey(_selectedDate),
        'openingBalance': double.tryParse(_openingBalanceCtrl.text) ?? 0,
        'billIncome': record?['autoBillIncome'] ?? 0,
        'otherIncome1Label': _otherIncome1LabelCtrl.text.trim(),
        'otherIncome1Amount': double.tryParse(_otherIncome1Ctrl.text) ?? 0,
        'otherIncome2Label': _otherIncome2LabelCtrl.text.trim(),
        'otherIncome2Amount': double.tryParse(_otherIncome2Ctrl.text) ?? 0,
        'expenses': double.tryParse(_expensesCtrl.text) ?? 0,
        'loansGivenCount': record?['loansGivenCount'] ?? 0,
        'loansGivenPrincipal': record?['loansGivenPrincipal'] ?? 0,
        'loansGivenIncome': record?['loansGivenIncome'] ?? 0,
        'loansGivenNetDisbursed': record?['loansGivenNetDisbursed'] ?? 0,
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily record saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadRecord();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select date to view records',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadRecord();
    }
  }

  void _changeDay(int delta) {
    final newDate = _selectedDate.add(Duration(days: delta));
    if (newDate.isAfter(DateTime.now().add(const Duration(days: 1)))) return;
    setState(() => _selectedDate = newDate);
    _loadRecord();
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final closing = _computeClosingBalance();

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.book_outlined,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Daybook',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text('Finance Cash In-Hand',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date Navigation
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _navBtn(
                                  Icons.chevron_left, () => _changeDay(-1)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Column(
                                  children: [
                                    Text(
                                      _formatDateDisplay(_selectedDate),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      _isToday(_selectedDate)
                                          ? 'TODAY'
                                          : _isYesterday(_selectedDate)
                                              ? 'YESTERDAY'
                                              : 'TAP TO CHANGE',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _navBtn(Icons.chevron_right,
                                  _isToday(_selectedDate)
                                      ? null
                                      : () => _changeDay(1)),
                              const SizedBox(width: 12),
                              if (!_isToday(_selectedDate))
                                GestureDetector(
                                  onTap: () {
                                    setState(() =>
                                        _selectedDate = DateTime.now());
                                    _loadRecord();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text('TODAY',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildBody(closing),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: onTap == null ? Colors.white30 : Colors.white, size: 18),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppTheme.errorColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text('Error loading record', style: TextStyle(
                color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRecord, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double closingBalance) {
    final record = _record ?? {};
    final isSaved = record['isSaved'] as bool? ?? false;
    final prevClosing = (record['previousDayClosing'] as num? ?? 0).toDouble();

    final autoBillIncome = (record['autoBillIncome'] as num? ?? 0).toDouble();
    final billPaymentsCount = (record['paymentsCount'] as num? ?? 0).toInt();
    final paymentsList =
        (record['paymentsList'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final loansGivenCount = (record['loansGivenCount'] as num? ?? 0).toInt();
    final loansGivenPrincipal =
        (record['loansGivenPrincipal'] as num? ?? 0).toDouble();
    final loansGivenIncome =
        (record['loansGivenIncome'] as num? ?? 0).toDouble();
    final loansGivenNetDisbursed =
        (record['loansGivenNetDisbursed'] as num? ?? 0).toDouble();
    final loansGivenList =
        (record['loansGivenList'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Save status badge
        _buildSaveStatusBadge(isSaved, record['updatedAt']),
        const SizedBox(height: 12),

        // ─── Closing Balance Card ─────────────────────────────────────────
        _buildClosingBalanceCard(closingBalance),
        const SizedBox(height: 16),

        // ─── Opening Balance ─────────────────────────────────────────────
        _buildSectionHeader(Icons.account_balance_wallet_outlined,
            'Opening Balance', Colors.indigo),
        const SizedBox(height: 8),
        _buildInputCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previous Day Closing: ${Formatters.currency(prevClosing)}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _openingBalanceCtrl,
                label: 'Opening Balance (₹)',
                icon: Icons.account_balance_wallet,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Incomes ─────────────────────────────────────────────────────
        _buildSectionHeader(Icons.trending_up_rounded, 'Incomes (+)', AppTheme.successColor),
        const SizedBox(height: 8),

        // Bill Income - Auto computed
        _buildInputCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: AppTheme.successColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Bill Income',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textDark)),
                        Text('Auto-computed from loan repayments',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(autoBillIncome),
                        style: const TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                      Text('$billPaymentsCount payments',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              if (paymentsList.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const Text('Payment Details',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                ...paymentsList.take(5).map((p) => _buildPaymentItem(p)),
                if (paymentsList.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${paymentsList.length - 5} more payments',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Other Income 1
        _buildInputCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.orange, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Other Income 1',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _otherIncome1LabelCtrl,
                      label: 'Description',
                      icon: Icons.label_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _otherIncome1Ctrl,
                      label: 'Amount (₹)',
                      icon: Icons.currency_rupee,
                      isNumeric: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Other Income 2
        _buildInputCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.teal, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Other Income 2',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _otherIncome2LabelCtrl,
                      label: 'Description',
                      icon: Icons.label_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _otherIncome2Ctrl,
                      label: 'Amount (₹)',
                      icon: Icons.currency_rupee,
                      isNumeric: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Outflows ─────────────────────────────────────────────────────
        _buildSectionHeader(Icons.trending_down_rounded, 'Outflows (-)', AppTheme.errorColor),
        const SizedBox(height: 8),

        // Loans Given
        _buildInputCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.handshake_outlined,
                        color: AppTheme.primaryColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loans Given Today',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textDark)),
                        Text('Auto-computed from new loans created',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '- ${Formatters.currency(loansGivenPrincipal)}',
                        style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      Text(
                        '+ ${Formatters.currency(loansGivenIncome)} income',
                        style: const TextStyle(
                            color: AppTheme.successColor, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              if (loansGivenCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _loanSummaryChip(
                        '$loansGivenCount loan${loansGivenCount != 1 ? 's' : ''}',
                        Colors.blue),
                    const SizedBox(width: 8),
                    _loanSummaryChip(
                        'Net given: ${Formatters.currency(loansGivenNetDisbursed)}',
                        Colors.deepPurple),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const Text('Loan Details',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                ...loansGivenList.map((l) => _buildLoanGivenItem(l)),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No loans disbursed today',
                    style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Day-to-day Expenses
        _buildInputCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppTheme.errorColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Day-to-Day Expenses',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _expensesCtrl,
                label: 'Total Expenses (₹)',
                icon: Icons.currency_rupee,
                isNumeric: true,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Summary Breakdown ────────────────────────────────────────────
        _buildSummaryCard(
          autoBillIncome: autoBillIncome,
          loansGivenPrincipal: loansGivenPrincipal,
          loansGivenIncome: loansGivenIncome,
          closing: closingBalance,
        ),
        const SizedBox(height: 16),

        // Notes
        _buildInputCard(
          child: _buildTextField(
            controller: _notesCtrl,
            label: 'Notes / Remarks (Optional)',
            icon: Icons.note_outlined,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 20),

        // Save Button
        AnimatedGradientButton(
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
          gradient: AppTheme.primaryGradient,
          child: const Text(
            'Save Daily Record',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSaveStatusBadge(bool isSaved, dynamic updatedAt) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSaved
                ? AppTheme.successColor.withValues(alpha: 0.12)
                : AppTheme.warningColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSaved ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                size: 12,
                color: isSaved ? AppTheme.successColor : AppTheme.warningColor,
              ),
              const SizedBox(width: 4),
              Text(
                isSaved ? 'Saved Record' : 'Draft — Not Saved',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSaved ? AppTheme.successColor : AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isSaved && updatedAt != null)
          Text(
            'Saved at ${_formatTime(updatedAt.toString())}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildClosingBalanceCard(double closingBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: closingBalance >= 0
              ? [const Color(0xFF2E7D32), const Color(0xFF388E3C)]
              : [const Color(0xFFC62828), const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (closingBalance >= 0
                    ? AppTheme.successColor
                    : AppTheme.errorColor)
                .withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded,
                  color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Total Cash In-Hand',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(closingBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finance closing balance for ${_formatDateDisplay(_selectedDate)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required double autoBillIncome,
    required double loansGivenPrincipal,
    required double loansGivenIncome,
    required double closing,
  }) {
    final opening = double.tryParse(_openingBalanceCtrl.text) ?? 0;
    final otherIncome1 = double.tryParse(_otherIncome1Ctrl.text) ?? 0;
    final otherIncome2 = double.tryParse(_otherIncome2Ctrl.text) ?? 0;
    final expenses = double.tryParse(_expensesCtrl.text) ?? 0;
    final totalIncome = autoBillIncome + loansGivenIncome + otherIncome1 + otherIncome2;
    final totalOutflow = loansGivenPrincipal + expenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.buttonBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cash Flow Summary',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _summaryRow('Opening Balance', opening, Colors.white, isTotal: false),
          _summaryRow('+ Bill Income', autoBillIncome, AppTheme.successColor, isTotal: false),
          _summaryRow('+ Loan Upfront Income', loansGivenIncome, AppTheme.successColor, isTotal: false),
          if (otherIncome1 > 0)
            _summaryRow('+ Other Income 1', otherIncome1, AppTheme.successColor, isTotal: false),
          if (otherIncome2 > 0)
            _summaryRow('+ Other Income 2', otherIncome2, AppTheme.successColor, isTotal: false),
          _summaryRow('− Loans Given (Principal)', loansGivenPrincipal,
              AppTheme.errorColor, isTotal: false, isNegative: true),
          _summaryRow('− Day Expenses', expenses, AppTheme.errorColor,
              isTotal: false, isNegative: true),
          const Divider(color: Colors.white24, height: 16),
          _summaryRow('Total Day Inflows', totalIncome, AppTheme.successColor, isTotal: false),
          _summaryRow('Total Day Outflows', totalOutflow, AppTheme.errorColor, isTotal: false, isNegative: true),
          const Divider(color: Colors.white24, height: 16),
          _summaryRow(
            '= Total In-Hand',
            closing,
            closing >= 0 ? AppTheme.accentLime : AppTheme.errorColor,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color color,
      {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: isTotal ? Colors.white : Colors.white60,
                fontSize: isTotal ? 13 : 12,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              )),
          Text(
            isNegative
                ? '- ${Formatters.currency(amount)}'
                : Formatters.currency(amount),
            style: TextStyle(
              color: color,
              fontSize: isTotal ? 15 : 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${p['customerName']} · ${p['loanNumber']} · Due #${p['dueNumber']}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Formatters.currency(p['amount']),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanGivenItem(Map<String, dynamic> l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${l['customerName']} (${l['customerPhone']})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l['type'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _miniChip('Loan: ${l['loanNumber']}', Colors.blueGrey),
                const SizedBox(width: 6),
                _miniChip(
                    'Principal: ${Formatters.currency(l['principal'])}',
                    AppTheme.errorColor),
                const SizedBox(width: 6),
                _miniChip(
                    'Upfront Income: ${Formatters.currency(l['upfrontIncome'])}',
                    AppTheme.successColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _loanSummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        prefixIcon: Icon(icon, size: 16, color: AppTheme.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day;
  }

  String _formatDateDisplay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = weekdays[d.weekday - 1];
    return '$wd, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
