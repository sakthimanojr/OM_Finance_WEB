import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/loan_provider.dart';

class NewLoanScreen extends ConsumerStatefulWidget {
  const NewLoanScreen({super.key, this.customerId});
  final String? customerId;

  @override
  ConsumerState<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends ConsumerState<NewLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Optional quick autofill from previous borrower
  String? _selectedCustomerId;

  // Borrower details controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _guarantorNameController = TextEditingController();
  final _guarantorPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _autoSyncPassword = true;

  // Loan controllers
  final _loanNumberController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _agreementFeeController = TextEditingController(text: '0');
  final _termCountController = TextEditingController();

  String _loanType = AppConstants.loanWeekly;
  String _disbursementSource = 'CASH'; // 'CASH' (Cash in Bag) or 'BANK' (Cash in Account)
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    _passwordController.addListener(_onPasswordChanged);
    if (widget.customerId != null) {
      _selectedCustomerId = widget.customerId;
    }
    if (_loanType == AppConstants.loanMonthly) {
      _interestRateController.text = '15';
      _agreementFeeController.text = '100';
      _termCountController.text = '5';
    } else if (_loanType == AppConstants.loanWeekly) {
      _termCountController.text = '10';
    }
    _loadNextLoanNumber();
  }

  void _onPhoneChanged() {
    if (_autoSyncPassword) {
      final phone = _phoneController.text.trim();
      _passwordController.text = phone;
    }
  }

  void _onPasswordChanged() {
    final phone = _phoneController.text.trim();
    if (_passwordController.text != phone && _autoSyncPassword) {
      setState(() => _autoSyncPassword = false);
    }
  }

  Future<void> _loadNextLoanNumber() async {
    try {
      final service = ref.read(loanServiceProvider);
      final next = await service.fetchNextLoanNumber();
      if (mounted && _loanNumberController.text.trim().isEmpty) {
        setState(() => _loanNumberController.text = next);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _fatherNameController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _guarantorNameController.dispose();
    _guarantorPhoneController.dispose();
    _passwordController.dispose();
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      helpText: 'Select Loan Start Date',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loanNumberController.text.trim().isEmpty) {
      setState(() {
        _error = 'Loan number is strictly required to create a loan.';
        _isSubmitting = false;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final service = ref.read(loanServiceProvider);
      final terms = _loanType == AppConstants.loanHighValue
          ? null
          : (_termCount > 0 ? _termCount : (_loanType == AppConstants.loanMonthly ? 5 : 10));

      final phone = _phoneController.text.trim();
      final customerPayload = {
        'name': _nameController.text.trim(),
        'phone': phone,
        if (_fatherNameController.text.trim().isNotEmpty) 'fatherName': _fatherNameController.text.trim(),
        if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
        if (_aadhaarController.text.trim().isNotEmpty) 'aadhaar': _aadhaarController.text.trim(),
        if (_panController.text.trim().isNotEmpty) 'pan': _panController.text.trim().toUpperCase(),
        if (_guarantorNameController.text.trim().isNotEmpty) 'guarantorName': _guarantorNameController.text.trim(),
        if (_guarantorPhoneController.text.trim().isNotEmpty) 'guarantorPhone': _guarantorPhoneController.text.trim(),
        'password': _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : phone,
      };
      final customerIdParam = _selectedCustomerId;

      final loan = await service.createLoan(
        customerId: customerIdParam,
        customer: customerPayload,
        loanNumber: _loanNumberController.text.trim(),
        type: _loanType,
        principal: _principal,
        interestRate: _rate,
        agreementFee: _fee,
        termCount: terms,
        startDate: _startDate,
        disbursementMethod: _disbursementSource,
      );

      ref.invalidate(customerListProvider);
      ref.invalidate(adminLoanListProvider);
      if (customerIdParam != null) {
        ref.invalidate(loanListProvider(customerIdParam));
      }

      if (mounted) {
        context.pop();
        context.push('/admin/loans/${loan.id}');
      }
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException && e.errors != null) {
        try {
          final errs = e.errors as Map;
          final details = errs.values.expand((v) => v is List ? v : [v]).join('\n');
          msg = details.isNotEmpty ? details : msg;
        } catch (_) {}
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final isHighValue = _loanType == AppConstants.loanHighValue;
    final customersAsync = ref.watch(customerListProvider);

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
            // Borrower Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_outline, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Borrower Details',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick autofill option for repeat borrowers (optional)
                  customersAsync.maybeWhen(
                    data: (customers) {
                      if (customers.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Quick Autofill from Previous Borrower (Optional)',
                              prefixIcon: Icon(Icons.bolt, color: Colors.amber, size: 20),
                              hintText: 'Select repeat borrower to autofill',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('None (Enter New Borrower)'),
                              ),
                              ...customers.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (id) {
                              setState(() {
                                _selectedCustomerId = id;
                                if (id != null) {
                                  final match = customers.where((c) => c.id == id).firstOrNull;
                                  if (match != null) {
                                    _nameController.text = match.name;
                                    _phoneController.text = match.phone;
                                    _fatherNameController.text = match.fatherName ?? '';
                                    _addressController.text = match.address ?? '';
                                    _aadhaarController.text = match.aadhaarLast4 ?? '';
                                    _panController.text = match.pan ?? '';
                                    _guarantorNameController.text = match.guarantorName ?? '';
                                    _guarantorPhoneController.text = match.guarantorPhone ?? '';
                                    _passwordController.text = '';
                                    _autoSyncPassword = false;
                                  }
                                } else {
                                  _nameController.clear();
                                  _phoneController.clear();
                                  _fatherNameController.clear();
                                  _addressController.clear();
                                  _aadhaarController.clear();
                                  _panController.clear();
                                  _guarantorNameController.clear();
                                  _guarantorPhoneController.clear();
                                  _passwordController.clear();
                                  _autoSyncPassword = true;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Borrower Full Name *',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      hintText: 'e.g. Ramesh Kumar',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Borrower full name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Mobile Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      hintText: '10-digit mobile number',
                      prefixText: '+91 ',
                    ),
                    onChanged: (phone) {
                      setState(() {});
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                      final clean = v.trim().replaceAll(RegExp(r'\D'), '');
                      if (clean.length < 10) return 'Enter a valid 10-digit number';
                      return null;
                    },
                  ),

                  // Live check for repeat borrower
                  Builder(
                    builder: (context) {
                      final phoneText = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
                      if (phoneText.length >= 10 && customersAsync.hasValue) {
                        final match = customersAsync.value!.where((c) => c.phone.contains(phoneText)).firstOrNull;
                        if (match != null) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_outlined, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previous borrower found: ${match.name} (${match.phone}). This will be registered as a new loan for them.',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 12),
                  // Father / Husband Name
                  TextFormField(
                    controller: _fatherNameController,
                    decoration: const InputDecoration(
                      labelText: "Father / Husband Name",
                      prefixIcon: Icon(Icons.family_restroom_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Residential Address',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Aadhaar & PAN
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar (12 Digits)',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _panController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Guarantor Details
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _guarantorNameController,
                          decoration: const InputDecoration(
                            labelText: 'Guarantor Name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _guarantorPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Guarantor Phone',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Customer App Login Credentials
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock_person_outlined, color: AppTheme.primaryColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Borrower App Login Credentials',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Info card about User ID and Password
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCustomerId != null
                                    ? 'Existing borrower logs in with mobile number. Leave password blank to keep current password.'
                                    : 'Borrower logs into the portal using their Mobile Number as User ID and this password.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'User ID: ${_phoneController.text.trim().isEmpty ? '(Enter mobile number above)' : _phoneController.text.trim()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: _selectedCustomerId != null ? 'New Password (Optional)' : 'Login Password *',
                      hintText: _selectedCustomerId != null ? 'Leave blank to keep current password' : 'Default: same as mobile number',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          ),
                          if (_selectedCustomerId == null)
                            IconButton(
                              icon: const Icon(Icons.refresh_outlined, size: 20),
                              onPressed: () {
                                setState(() {
                                  _passwordController.text = _phoneController.text.trim();
                                  _autoSyncPassword = true;
                                });
                              },
                              tooltip: 'Reset to mobile number',
                            ),
                        ],
                      ),
                    ),
                    validator: (v) {
                      if (_selectedCustomerId != null) {
                        if (v != null && v.trim().isNotEmpty && v.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      }
                      final pass = (v == null || v.trim().isEmpty) ? _phoneController.text.trim() : v.trim();
                      if (pass.isEmpty) return 'Password is required';
                      if (pass.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loan Details Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLime.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.monetization_on_outlined, color: AppTheme.textDark, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Loan & Disbursal Details',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Loan Number
                  TextFormField(
                    controller: _loanNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Loan Number *',
                      hintText: 'e.g. LN-004',
                      prefixIcon: Icon(Icons.numbers, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Loan number is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Loan Type
                  const Text('Loan Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

                  // Principal Amount
                  TextFormField(
                    controller: _principalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Principal Amount (₹) *',
                      hintText: 'e.g. 10000',
                      prefixText: '₹ ',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v == null || num.tryParse(v) == null || num.parse(v) <= 0) ? 'Enter a valid amount' : null,
                  ),
                  const SizedBox(height: 12),

                  // Interest Rate
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

                  // Agreement Fee
                  if (!isHighValue) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _agreementFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _loanType == AppConstants.loanMonthly
                            ? 'Agreement Fee / Extra Charges (₹) — Default ₹100'
                            : 'Agreement Fee (₹)',
                        hintText: _loanType == AppConstants.loanMonthly ? '100' : '0',
                        prefixText: '₹ ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  // Term count
                  if (!isHighValue) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _termCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _loanType == AppConstants.loanWeekly
                            ? 'Number of Weeks *'
                            : 'Number of Months — Default 5 Months *',
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
                    title: const Text('Start Date', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: _pickDate,
                  ),
                  const Divider(height: 24),

                  // Disbursement Source (Giving Money From)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Giving Money From',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose where money is disbursed from. Upfront interest will also be collected into this account.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _disbursementSource = 'CASH'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _disbursementSource == 'CASH'
                                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _disbursementSource == 'CASH'
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                                width: _disbursementSource == 'CASH' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wallet_outlined,
                                  color: _disbursementSource == 'CASH'
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cash in Bag',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: _disbursementSource == 'CASH'
                                              ? AppTheme.primaryColor
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Hand cash',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_disbursementSource == 'CASH')
                                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _disbursementSource = 'BANK'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _disbursementSource == 'BANK'
                                  ? Colors.indigo.withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _disbursementSource == 'BANK'
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                                width: _disbursementSource == 'BANK' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  color: _disbursementSource == 'BANK'
                                      ? Colors.indigo
                                      : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cash in Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: _disbursementSource == 'BANK'
                                              ? Colors.indigo
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Bank transfer / UPI',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_disbursementSource == 'BANK')
                                  const Icon(Icons.check_circle, color: Colors.indigo, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Loan Preview
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
                        const Divider(height: 18, thickness: 1),
                        Row(
                          children: [
                            Icon(
                              _disbursementSource == 'BANK' ? Icons.account_balance : Icons.wallet,
                              size: 15,
                              color: AppTheme.textDark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _disbursementSource == 'BANK'
                                    ? 'Giving from: Cash in Account (Bank). Disbursed net amount is deducted from Bank, and upfront interest is credited back to Bank.'
                                    : 'Giving from: Cash in Bag (Hand). Disbursed net amount is deducted from Bag, and upfront interest is credited back to Bag.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                    ),
                  ],
                ),
              ),
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
