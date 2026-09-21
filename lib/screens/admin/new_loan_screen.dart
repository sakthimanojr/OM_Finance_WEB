import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
      };
    }
    final interest = (_principal * _rate) / 100;
    final disbursed = _principal - interest - _fee;
    // Weekly: customer repays only principal in installments (interest deducted upfront)
    // Monthly: customer repays principal + interest over term
    final totalRepayable = _loanType == AppConstants.loanWeekly ? _principal : _principal + interest;
    final installment = _termCount > 0 ? (_loanType == AppConstants.loanWeekly ? _principal / _termCount : totalRepayable / _termCount) : 0;
    return {'disbursed': disbursed, 'installment': installment, 'totalRepayable': totalRepayable};
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
      final loan = await service.createLoan(
        customerId: _customerIdController.text.trim(),
        loanNumber: _loanNumberController.text.trim(),
        type: _loanType,
        principal: _principal,
        interestRate: _rate,
        agreementFee: _fee,
        termCount: _loanType == AppConstants.loanHighValue ? null : _termCount,
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
              onSelectionChanged: (selection) => setState(() => _loanType = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Principal Amount (₹) *'),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || num.tryParse(v) == null || num.parse(v) <= 0) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _interestRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isHighValue ? 'Monthly Interest Rate (%) *' : 'Interest Rate (%) *',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || num.tryParse(v) == null) ? 'Enter a valid rate' : null,
            ),
            if (!isHighValue) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _agreementFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Agreement Fee (₹)'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (!isHighValue) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _termCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _loanType == AppConstants.loanWeekly ? 'Number of Weeks *' : 'Number of Months *',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Enter a valid term' : null,
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
              Container(
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
                        const Text('Loan Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _previewRow('Disbursed to customer', '₹${preview['disbursed']?.toStringAsFixed(2)}'),
                    _previewRow(
                      isHighValue ? 'Monthly interest' : 'Installment amount',
                      '₹${preview['installment']?.toStringAsFixed(2)}',
                    ),
                    if (preview['totalRepayable'] != null)
                      _previewRow('Total repayable', '₹${preview['totalRepayable']?.toStringAsFixed(2)}'),
                  ],
                ),
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

  Widget _previewRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 13)),
          ],
        ),
      );
}
