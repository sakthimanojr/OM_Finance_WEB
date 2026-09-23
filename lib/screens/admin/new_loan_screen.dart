import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../providers/loan_provider.dart';

class NewLoanScreen extends ConsumerStatefulWidget {
  const NewLoanScreen({super.key, this.customerId});
  final String? customerId;

  @override
  ConsumerState<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends ConsumerState<NewLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _loanNumberController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _agreementFeeController = TextEditingController(text: '0');
  final _termCountController = TextEditingController();

  String _loanType = AppConstants.loanWeekly;
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) _customerIdController.text = widget.customerId!;
    if (_loanType == AppConstants.loanMonthly) {
      _interestRateController.text = '15';
      _agreementFeeController.text = '100';
      _termCountController.text = '5';
    } else if (_loanType == AppConstants.loanWeekly) {
      _termCountController.text = '10';
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _loanNumberController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _agreementFeeController.dispose();
    _termCountController.dispose();
    super.dispose();
  }

  num get _principal => num.tryParse(_principalController.text) ?? 0;
  num get _rate => num.tryParse(_interestRateController.text) ?? 0;
  num get _fee => num.tryParse(_agreementFeeController.text) ?? 0;
  int get _termCount => int.tryParse(_termCountController.text) ?? 0;

  /// Client-side preview of the disbursal math, mirroring the backend
  /// calculators, so the admin can see the numbers before submitting.
  Map<String, num> get _preview {
    if (_loanType == AppConstants.loanHighValue) {
      return {
        'disbursed': _principal,
        'installment': (_principal * _rate) / 100,
        'totalRepayable': _principal,
        'upfrontInterest': 0,
        'upfrontFee': 0,
        'totalDeductions': 0,
      };
    }
    final interest = (_principal * _rate) / 100;
    final fee = _fee;
    final totalDeductions = interest + fee;
    final disbursed = _principal - totalDeductions;
    // Weekly & Monthly: customer repays principal in installments (interest & fee deducted upfront)
    final totalRepayable = _principal;
    final terms = _termCount > 0 ? _termCount : (_loanType == AppConstants.loanMonthly ? 5 : 10);
    final installment = terms > 0 ? (totalRepayable / terms) : 0;
    return {
      'disbursed': disbursed,
      'installment': installment,
      'totalRepayable': totalRepayable,
      'upfrontInterest': interest,
      'upfrontFee': fee,
      'totalDeductions': totalDeductions,
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final service = ref.read(loanServiceProvider);
      final terms = _loanType == AppConstants.loanHighValue
          ? null
          : (_termCount > 0 ? _termCount : (_loanType == AppConstants.loanMonthly ? 5 : 10));
      final loan = await service.createLoan(
        customerId: _customerIdController.text.trim(),
        loanNumber: _loanNumberController.text.trim(),
        type: _loanType,
        principal: _principal,
        interestRate: _rate,
        agreementFee: _fee,
        termCount: terms,
        startDate: _startDate,
      );
      ref.invalidate(loanListProvider(_customerIdController.text.trim()));
      if (mounted) {
        context.pop();
        context.push('/admin/loans/${loan.id}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final isHighValue = _loanType == AppConstants.loanHighValue;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('New Loan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerIdController,
              decoration: const InputDecoration(labelText: 'Customer ID *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              enabled: widget.customerId == null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loanNumberController,
              decoration: const InputDecoration(
                labelText: 'Loan Number *',
                hintText: 'e.g. LN-001',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a loan number' : null,
            ),
            const SizedBox(height: 16),
            const Text('Loan Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: AppConstants.loanWeekly, label: Text('Weekly')),
                ButtonSegment(value: AppConstants.loanMonthly, label: Text('Monthly EMI')),
                ButtonSegment(value: AppConstants.loanHighValue, label: Text('High-Value')),
              ],
              selected: {_loanType},
              onSelectionChanged: (selection) => setState(() {
                _loanType = selection.first;
                if (_loanType == AppConstants.loanMonthly) {
                  // Monthly defaults: 15% interest, ₹100 agreement fee, 5 months (all editable)
                  if (_interestRateController.text.trim().isEmpty || _interestRateController.text.trim() == '0') {
                    _interestRateController.text = '15';
                  }
                  if (_agreementFeeController.text.trim().isEmpty || _agreementFeeController.text.trim() == '0') {
                    _agreementFeeController.text = '100';
                  }
                  if (_termCountController.text.trim().isEmpty || _termCountController.text.trim() == '10') {
                    _termCountController.text = '5';
                  }
                } else if (_loanType == AppConstants.loanWeekly) {
                  if (_termCountController.text.trim().isEmpty || _termCountController.text.trim() == '5') {
                    _termCountController.text = '10';
                  }
                  if (_agreementFeeController.text.trim() == '100') {
                    _agreementFeeController.text = '0';
                  }
                }
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Principal Amount (₹) *',
                hintText: 'e.g. 20000',
                prefixText: '₹ ',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || num.tryParse(v) == null || num.parse(v) <= 0) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isHighValue
                    ? 'Monthly Interest Rate (%) *'
                    : (_loanType == AppConstants.loanMonthly
                        ? 'Interest Rate (%) — Default 15% (Editable) *'
                        : 'Interest Rate (%) *'),
                hintText: _loanType == AppConstants.loanMonthly ? '15' : 'e.g. 10',
                suffixText: '%',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || num.tryParse(v) == null) ? 'Enter a valid rate' : null,
            ),
            if (!isHighValue) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _agreementFeeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _loanType == AppConstants.loanMonthly
                      ? 'Agreement Fee / Extra Charges (₹) — Default ₹100 (Editable)'
                      : 'Agreement Fee (₹)',
                  hintText: _loanType == AppConstants.loanMonthly ? '100' : '0',
                  prefixText: '₹ ',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (!isHighValue) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _termCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _loanType == AppConstants.loanWeekly
                      ? 'Number of Weeks *'
                      : 'Number of Months — Default 5 Months (Editable) *',
                  hintText: _loanType == AppConstants.loanWeekly ? '10' : '5',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (_loanType == AppConstants.loanMonthly && (v == null || v.trim().isEmpty)) {
                    return null;
                  }
                  return (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                      ? 'Enter a valid term'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            if (_principal > 0)
              Builder(
                builder: (context) {
                  final terms = _termCount > 0 ? _termCount : (_loanType == AppConstants.loanMonthly ? 5 : 10);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLime,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentLime.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.buttonBlack.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calculate_outlined, color: AppTheme.buttonBlack, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _loanType == AppConstants.loanMonthly
                                    ? 'Monthly Loan Preview ($terms Months @ $_rate%)'
                                    : 'Loan Preview',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _previewRow('Principal Amount', Formatters.currency(_principal)),
                        if (!isHighValue) ...[
                          _previewRow('Upfront Interest ($_rate%)', Formatters.currency(preview['upfrontInterest'] ?? 0)),
                          _previewRow('Agreement Fee (Extra Charges)', Formatters.currency(preview['upfrontFee'] ?? 0)),
                          _previewRow('Total Deductions', Formatters.currency(preview['totalDeductions'] ?? 0), isBold: true),
                          const Divider(height: 18, thickness: 1),
                        ],
                        _previewRow(
                          'Net Disbursed to Customer',
                          Formatters.currency(preview['disbursed'] ?? 0),
                          isAccent: true,
                        ),
                        _previewRow(
                          isHighValue
                              ? 'Monthly Interest Due'
                              : (_loanType == AppConstants.loanMonthly
                                  ? 'Monthly Installment ($terms months)'
                                  : 'Weekly Installment ($terms weeks)'),
                          '${Formatters.currency(preview['installment'] ?? 0)} / ${_loanType == AppConstants.loanMonthly ? "month" : "week"}',
                        ),
                        if (preview['totalRepayable'] != null)
                          _previewRow(
                            'Total Repayable (Principal)',
                            '${Formatters.currency(preview['totalRepayable'] ?? 0)} ($terms x ${Formatters.currency(preview['installment'] ?? 0)})',
                          ),
                      ],
                    ),
                  );
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
            ],
            const SizedBox(height: 24),
            AnimatedGradientButton(
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              gradient: AppTheme.primaryGradient,
              icon: Icons.add_card_outlined,
              child: const Text('Create Loan & Disburse'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool isBold = false, bool isAccent = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isAccent ? AppTheme.textDark : AppTheme.textMuted,
                fontWeight: (isBold || isAccent) ? FontWeight.bold : FontWeight.normal,
                fontSize: isAccent ? 13.5 : 13,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: (isBold || isAccent) ? FontWeight.w800 : FontWeight.w600,
                color: isAccent ? AppTheme.primaryDark : AppTheme.textDark,
                fontSize: isAccent ? 14 : 13,
              ),
            ),
          ],
        ),
      );
}
