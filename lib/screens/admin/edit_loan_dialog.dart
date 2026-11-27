import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/loan_model.dart';
import '../../providers/auth_provider.dart';
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

  // Borrower Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Loan Identification & Financial Controllers
  late TextEditingController _loanNumberController;
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _agreementFeeController;
  late TextEditingController _termCountController;

  late String _loanType;
  late String _disbursementMethod;
  late String _loanStatus;
  late DateTime _startDate;
  late TextEditingController _paidDuesCountController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.loan.customerName ?? '');
    _phoneController = TextEditingController(text: widget.loan.customerPhone ?? '');
    _loanNumberController = TextEditingController(text: widget.loan.loanNumber ?? '');
    _principalController = TextEditingController(text: widget.loan.principal.toString());
    _interestRateController = TextEditingController(
      text: widget.loan.interestRate > 0
          ? widget.loan.interestRate.toString()
          : (widget.loan.type == 'MONTHLY' ? '15' : '10'),
    );
    _agreementFeeController = TextEditingController(
      text: widget.loan.agreementFee > 0
          ? widget.loan.agreementFee.toString()
          : (widget.loan.type == 'MONTHLY' ? '100' : '0'),
    );
    _termCountController = TextEditingController(
      text: (widget.loan.termCount ?? (widget.loan.type == 'MONTHLY' ? 5 : 10)).toString(),
    );

    _loanType = widget.loan.type;
    _disbursementMethod = widget.loan.disbursementMethod.isNotEmpty ? widget.loan.disbursementMethod : 'CASH';
    _loanStatus = widget.loan.status;
    _startDate = widget.loan.startDate;
    final currentlyPaid = widget.loan.dues.where((d) => d.status == 'PAID').length;
    _paidDuesCountController = TextEditingController(text: (currentlyPaid > 0 ? currentlyPaid : 2).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _loanNumberController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _agreementFeeController.dispose();
    _termCountController.dispose();
    _paidDuesCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      helpText: 'Select Loan Created / Start Date',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  // Live calculation preview
  Map<String, num> _calculatePreview() {
    final principal = num.tryParse(_principalController.text) ?? 0;
    final rate = num.tryParse(_interestRateController.text) ?? 0;
    final fee = num.tryParse(_agreementFeeController.text) ?? 0;
    final terms = int.tryParse(_termCountController.text) ??
        (widget.loan.termCount ?? (_loanType == 'MONTHLY' ? 5 : 10));

    if (principal <= 0) {
      return {'disbursed': 0, 'installment': 0, 'total': 0, 'totalDeductions': 0};
    }

    if (_loanType == 'WEEKLY') {
      final interest = (principal * rate) / 100;
      final totalDeductions = interest + fee;
      final disbursed = principal - totalDeductions;
      final total = principal;
      final installment = terms > 0 ? (principal / terms) : principal;
      return {
        'disbursed': disbursed,
        'installment': installment,
        'total': total,
        'upfrontInterest': interest,
        'upfrontFee': fee,
        'totalDeductions': totalDeductions,
      };
    } else if (_loanType == 'MONTHLY') {
      final interest = (principal * rate) / 100;
      final totalDeductions = interest + fee;
      final disbursed = principal - totalDeductions;
      final total = principal;
      final effectiveTerms = terms > 0 ? terms : 5;
      final installment = effectiveTerms > 0 ? (total / effectiveTerms) : total;
      return {
        'disbursed': disbursed,
        'installment': installment,
        'total': total,
        'upfrontInterest': interest,
        'upfrontFee': fee,
        'totalDeductions': totalDeductions,
      };
    } else {
      // HIGH_VALUE
      final monthlyInterest = (principal * rate) / 100;
      return {'disbursed': principal, 'installment': monthlyInterest, 'total': principal, 'totalDeductions': 0};
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
    final paidCount = (_loanStatus == 'ACTIVE' && widget.loan.status == 'CLOSED')
        ? int.tryParse(_paidDuesCountController.text)
        : null;

    try {
      final service = LoanService();
      await service.updateLoan(
        loanId: widget.loan.id,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        loanNumber: _loanNumberController.text.trim().isNotEmpty ? _loanNumberController.text.trim() : null,
        startDate: _startDate,
        type: _loanType,
        disbursementMethod: _disbursementMethod,
        status: _loanStatus,
        paidDuesCount: paidCount,
        principal: principal,
        interestRate: rate,
        agreementFee: fee,
        termCount: _loanType != 'HIGH_VALUE' ? terms : null,
      );

      // Invalidate all providers so UI updates automatically
      ref.invalidate(loanDetailProvider(widget.loan.id));
      ref.invalidate(loanListProvider(widget.loan.customerId));
      ref.invalidate(adminLoanListProvider);
      ref.invalidate(customerDetailProvider(widget.loan.customerId));
      ref.invalidate(customerListProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete loan details updated successfully!'),
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
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState.user?.isSuperAdmin ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                                'Edit Loan Details',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${widget.loan.loanNumber ?? "No ID"} • $_loanType',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    if (!isSuperAdmin) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, color: AppTheme.errorColor, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Access Denied: Only Super Admin can modify complete loan records.',
                                style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
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
                      const SizedBox(height: 14),
                    ],

                    // SECTION 1: Borrower Information
                    _buildSectionHeader(Icons.person_outline, 'BORROWER INFORMATION'),
                    const SizedBox(height: 10),
                    // Responsive: stack on narrow, side-by-side on wide
                    if (isNarrow) ...[
                      TextFormField(
                        controller: _nameController,
                        enabled: isSuperAdmin,
                        decoration: const InputDecoration(
                          labelText: 'Borrower Name *',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        enabled: isSuperAdmin,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          counterText: '',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Phone required';
                          final clean = val.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 10) return '10 digits required';
                          return null;
                        },
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _nameController,
                              enabled: isSuperAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Borrower Name *',
                                prefixIcon: Icon(Icons.badge_outlined, size: 20),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: isSuperAdmin,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                counterText: '',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Phone required';
                                final clean = val.replaceAll(RegExp(r'\D'), '');
                                if (clean.length < 10) return '10 digits required';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),

                    // SECTION 2: Loan Setup & Dates
                    _buildSectionHeader(Icons.calendar_month_outlined, 'LOAN IDENTIFIER & DATE'),
                    const SizedBox(height: 10),
                    if (isNarrow) ...[
                      TextFormField(
                        controller: _loanNumberController,
                        enabled: isSuperAdmin,
                        decoration: const InputDecoration(
                          labelText: 'Loan Number *',
                          prefixIcon: Icon(Icons.tag, size: 20),
                          hintText: 'e.g. LN-103',
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Loan number required' : null,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: isSuperAdmin ? _pickDate : null,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Loan Created Date *',
                            prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            Formatters.date(_startDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _loanNumberController,
                              enabled: isSuperAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Loan Number *',
                                prefixIcon: Icon(Icons.tag, size: 20),
                                hintText: 'e.g. LN-103',
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Loan number required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: isSuperAdmin ? _pickDate : null,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Loan Created Date *',
                                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                                child: Text(
                                  Formatters.date(_startDate),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (isNarrow) ...[
                      DropdownButtonFormField<String>(
                        value: _loanType,
                        decoration: const InputDecoration(
                          labelText: 'Loan Type *',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
                          DropdownMenuItem(value: 'MONTHLY', child: Text('MONTHLY')),
                          DropdownMenuItem(value: 'HIGH_VALUE', child: Text('HIGH VALUE')),
                        ],
                        onChanged: isSuperAdmin
                            ? (val) {
                                if (val != null) {
                                  setState(() {
                                    _loanType = val;
                                    if (val == 'MONTHLY') {
                                      if (_termCountController.text.trim().isEmpty || _termCountController.text == '10') {
                                        _termCountController.text = '5';
                                      }
                                      if (_interestRateController.text == '10') {
                                        _interestRateController.text = '15';
                                      }
                                    } else if (val == 'WEEKLY') {
                                      if (_termCountController.text.trim().isEmpty || _termCountController.text == '5') {
                                        _termCountController.text = '10';
                                      }
                                    }
                                  });
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _disbursementMethod,
                        decoration: const InputDecoration(
                          labelText: 'Disbursement Mode',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('Cash in Hand/Bag')),
                          DropdownMenuItem(value: 'BANK', child: Text('Bank Transfer')),
                        ],
                        onChanged: isSuperAdmin
                            ? (val) {
                                if (val != null) setState(() => _disbursementMethod = val);
                              }
                            : null,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _loanType,
                              decoration: const InputDecoration(
                                labelText: 'Loan Type *',
                                prefixIcon: Icon(Icons.category_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
                                DropdownMenuItem(value: 'MONTHLY', child: Text('MONTHLY')),
                                DropdownMenuItem(value: 'HIGH_VALUE', child: Text('HIGH VALUE')),
                              ],
                              onChanged: isSuperAdmin
                                  ? (val) {
                                      if (val != null) {
                                        setState(() {
                                          _loanType = val;
                                          if (val == 'MONTHLY') {
                                            if (_termCountController.text.trim().isEmpty || _termCountController.text == '10') {
                                              _termCountController.text = '5';
                                            }
                                            if (_interestRateController.text == '10') {
                                              _interestRateController.text = '15';
                                            }
                                          } else if (val == 'WEEKLY') {
                                            if (_termCountController.text.trim().isEmpty || _termCountController.text == '5') {
                                              _termCountController.text = '10';
                                            }
                                          }
                                        });
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _disbursementMethod,
                              decoration: const InputDecoration(
                                labelText: 'Disbursement Mode',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'CASH', child: Text('Cash in Hand/Bag')),
                                DropdownMenuItem(value: 'BANK', child: Text('Bank Transfer')),
                              ],
                              onChanged: isSuperAdmin
                                  ? (val) {
                                      if (val != null) setState(() => _disbursementMethod = val);
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _loanStatus,
                      decoration: const InputDecoration(
                        labelText: 'Loan Status *',
                        prefixIcon: Icon(Icons.sync_alt_rounded, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED')),
                        DropdownMenuItem(value: 'OVERDUE', child: Text('OVERDUE')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                      ],
                      onChanged: isSuperAdmin
                          ? (val) {
                              if (val != null) setState(() => _loanStatus = val);
                            }
                          : null,
                    ),
                    if (_loanStatus == 'ACTIVE' && widget.loan.status == 'CLOSED') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Reactivating Closed Loan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _paidDuesCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Number of Paid Dues to Keep *',
                                hintText: 'e.g. 2',
                                helperText: 'Dues after this number will be marked PENDING',
                              ),
                              validator: (val) {
                                if (_loanStatus == 'ACTIVE' && widget.loan.status == 'CLOSED') {
                                  final n = int.tryParse(val ?? '');
                                  if (n == null || n < 0) return 'Enter a valid number (e.g. 2)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // SECTION 3: Financial Details
                    _buildSectionHeader(Icons.currency_rupee, 'FINANCIAL TERMS'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _principalController,
                      enabled: isSuperAdmin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Principal Amount (₹) *',
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
                    const SizedBox(height: 10),
                    // Interest Rate + Agreement Fee — always stack on mobile
                    if (isNarrow) ...[
                      TextFormField(
                        controller: _interestRateController,
                        enabled: isSuperAdmin,
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
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _agreementFeeController,
                        enabled: isSuperAdmin,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Agreement Fee (₹)',
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _interestRateController,
                              enabled: isSuperAdmin,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _agreementFeeController,
                              enabled: isSuperAdmin,
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
                    const SizedBox(height: 10),

                    if (_loanType != 'HIGH_VALUE') ...[
                      TextFormField(
                        controller: _termCountController,
                        enabled: isSuperAdmin,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _loanType == 'WEEKLY' ? 'Term (Weeks) *' : 'Term (Months) *',
                          hintText: _loanType == 'WEEKLY' ? 'e.g. 10' : 'e.g. 5',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Term count required';
                          final intVal = int.tryParse(val.trim());
                          if (intVal == null || intVal < 1) return 'Must be 1 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Live Preview Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
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
                          if (_loanType != 'HIGH_VALUE') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('Total Deductions (Int + Fee):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))),
                                Text(
                                  Formatters.currency(preview['totalDeductions'] ?? 0),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.errorColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
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
                                _loanType == 'HIGH_VALUE' ? 'Monthly Interest Due:' : 'Installment per Due:',
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
                    const SizedBox(height: 10),
                    const Text(
                      'Note: Saving changes will recalculate unpaid dues, loan schedules, customer records, and financial reports.',
                      style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                    ),
                    const SizedBox(height: 18),

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
                            onPressed: (_isSaving || !isSuperAdmin) ? null : _submit,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
