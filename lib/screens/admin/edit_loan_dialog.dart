import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/loan_service.dart';

class EditLoanDialog extends ConsumerStatefulWidget {
  const EditLoanDialog({super.key, required this.loan});
  final Loan loan;

  static Future<bool?> show(BuildContext context, Loan loan) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditLoanDialog(loan: loan),
    );
  }

  @override
  ConsumerState<EditLoanDialog> createState() => _EditLoanDialogState();
}

class _EditLoanDialogState extends ConsumerState<EditLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _agreementFeeController;
  late TextEditingController _termCountController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _principalController = TextEditingController(text: widget.loan.principal.toString());
    _interestRateController = TextEditingController(text: widget.loan.interestRate.toString());
    _agreementFeeController = TextEditingController(text: '0');
    _termCountController = TextEditingController(text: (widget.loan.termCount ?? 10).toString());
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestRateController.dispose();
    _agreementFeeController.dispose();
    _termCountController.dispose();
    super.dispose();
  }

  // Live calculation preview
  Map<String, num> _calculatePreview() {
    final principal = num.tryParse(_principalController.text) ?? 0;
    final rate = num.tryParse(_interestRateController.text) ?? 0;
    final fee = num.tryParse(_agreementFeeController.text) ?? 0;
    final terms = int.tryParse(_termCountController.text) ?? (widget.loan.termCount ?? 1);

    if (principal <= 0) {
      return {'disbursed': 0, 'installment': 0, 'total': 0};
    }

    if (widget.loan.type == 'WEEKLY') {
      final interest = (principal * rate) / 100;
      final disbursed = principal - interest - fee;
      final total = principal;
      final installment = terms > 0 ? (principal / terms) : principal;
      return {'disbursed': disbursed, 'installment': installment, 'total': total};
    } else if (widget.loan.type == 'MONTHLY') {
      final interest = (principal * rate) / 100;
      final disbursed = principal - interest - fee;
      final total = principal + interest;
      final installment = terms > 0 ? (total / terms) : total;
      return {'disbursed': disbursed, 'installment': installment, 'total': total};
    } else {
      // HIGH_VALUE
      final monthlyInterest = (principal * rate) / 100;
      return {'disbursed': principal, 'installment': monthlyInterest, 'total': principal};
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final principal = num.tryParse(_principalController.text);
    final rate = num.tryParse(_interestRateController.text);
    final fee = num.tryParse(_agreementFeeController.text);
    final terms = int.tryParse(_termCountController.text);

    try {
      final service = LoanService();
      await service.updateLoan(
        loanId: widget.loan.id,
        principal: principal,
        interestRate: rate,
        agreementFee: fee,
        termCount: widget.loan.type != 'HIGH_VALUE' ? terms : null,
      );

      // Invalidate all providers so everything updates automatically
      ref.invalidate(loanDetailProvider(widget.loan.id));
      ref.invalidate(loanListProvider(widget.loan.customerId));
      ref.invalidate(adminLoanListProvider);
      ref.invalidate(customerDetailProvider(widget.loan.customerId));
      ref.invalidate(customerListProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan amount updated & schedules recalculated successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _calculatePreview();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Loan Amount',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          '${widget.loan.loanNumber != null ? "Loan #${widget.loan.loanNumber} • " : ""}${widget.loan.type}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Principal Amount
              TextFormField(
                controller: _principalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Loan Principal Amount (₹) *',
                  prefixText: '₹ ',
                  hintText: 'e.g. 50000',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Principal is required';
                  final numVal = num.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Interest Rate & Agreement Fee
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interest Rate (%) *',
                        suffixText: '%',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Rate is required';
                        final numVal = num.tryParse(val.trim());
                        if (numVal == null || numVal < 0) return 'Valid rate required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _agreementFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Agreement Fee (₹)',
                        prefixText: '₹ ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Term Count if applicable
              if (widget.loan.type != 'HIGH_VALUE') ...[
                TextFormField(
                  controller: _termCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.loan.type == 'WEEKLY' ? 'Term (Weeks) *' : 'Term (Months) *',
                    hintText: 'e.g. 10',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Term count required';
                    final intVal = int.tryParse(val.trim());
                    if (intVal == null || intVal < 1) return 'Must be 1 or more';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Live Preview Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPDATED LOAN SUMMARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Disbursed to Customer:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          Formatters.currency(preview['disbursed']),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.loan.type == 'HIGH_VALUE' ? 'Monthly Interest Due:' : 'Installment per Due:',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        Text(
                          Formatters.currency(preview['installment']),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Repayable:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          Formatters.currency(preview['total']),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Updating this will recalculate pending dues and reflect in dues, customer profile, and financial reports.',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
