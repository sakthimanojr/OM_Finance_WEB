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

  // Toggle between existing customer and new customer
  bool _isNewCustomer = false;

  // Existing customer selection
  String? _selectedCustomerId;

  // New customer controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _guarantorNameController = TextEditingController();
  final _guarantorPhoneController = TextEditingController();

  // Loan controllers
  final _loanNumberController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _agreementFeeController = TextEditingController(text: '0');
  final _termCountController = TextEditingController();

  String _loanType = AppConstants.loanWeekly;
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;
  String? _error;
  bool _showMoreCustomerFields = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _selectedCustomerId = widget.customerId;
      _isNewCustomer = false;
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
    _nameController.dispose();
    _phoneController.dispose();
    _fatherNameController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _guarantorNameController.dispose();
    _guarantorPhoneController.dispose();
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

      Map<String, dynamic>? customerPayload;
      String? customerIdParam;

      if (_isNewCustomer) {
        final phone = _phoneController.text.trim();
        customerPayload = {
          'name': _nameController.text.trim(),
          'phone': phone,
          if (_fatherNameController.text.trim().isNotEmpty) 'fatherName': _fatherNameController.text.trim(),
          if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
          if (_aadhaarController.text.trim().isNotEmpty) 'aadhaar': _aadhaarController.text.trim(),
          if (_panController.text.trim().isNotEmpty) 'pan': _panController.text.trim().toUpperCase(),
          if (_guarantorNameController.text.trim().isNotEmpty) 'guarantorName': _guarantorNameController.text.trim(),
          if (_guarantorPhoneController.text.trim().isNotEmpty) 'guarantorPhone': _guarantorPhoneController.text.trim(),
          'password': phone,
        };
      } else {
        customerIdParam = _selectedCustomerId;
      }

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
            // Customer Mode Selector Header
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Customer Information',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.customerId == null)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.people_outline, size: 18),
                          label: Text('Existing Customer'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: Text('New Customer'),
                        ),
                      ],
                      selected: {_isNewCustomer},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _isNewCustomer = selection.first;
                          _error = null;
                        });
                      },
                    ),
                  const SizedBox(height: 14),

                  // Existing Customer UI
                  if (!_isNewCustomer) ...[
                    customersAsync.when(
                      data: (customers) {
                        final active = customers.where((c) => c.status == 'ACTIVE').toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCustomerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Customer *',
                                prefixIcon: Icon(Icons.search, size: 20),
                                hintText: 'Search or choose customer',
                              ),
                              items: active
                                  .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCustomerId = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'Please select a customer' : null,
                            ),
                            if (_selectedCustomerId != null)
                              Builder(
                                builder: (context) {
                                  final cust = active.firstWhere(
                                    (c) => c.id == _selectedCustomerId,
                                    orElse: () => Customer(
                                      id: _selectedCustomerId!,
                                      name: 'Selected Customer',
                                      phone: '',
                                      status: 'ACTIVE',
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                  return Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_user_outlined, color: AppTheme.primaryColor, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cust.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                              ),
                                              Text(
                                                'Phone: ${cust.phone}${cust.address != null && cust.address!.isNotEmpty ? " • ${cust.address}" : ""}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              ),
                                              const Text(
                                                'Creating an additional new loan for this customer.',
                                                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading customers: $err', style: const TextStyle(color: Colors.red)),
                    ),
                  ],

                  // New Customer UI
                  if (_isNewCustomer) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Full Name *',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        hintText: 'e.g. Ramesh Kumar',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Customer name is required' : null,
                    ),
                    const SizedBox(height: 12),
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
                        // Smart detection: check if phone matches existing customer
                        setState(() {});
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                        final clean = v.trim().replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),

                    // Smart detection banner if phone already exists
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
                                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Existing customer found: ${match.name} (${match.phone}). This will be registered as a second loan for them.',
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
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

                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => setState(() => _showMoreCustomerFields = !_showMoreCustomerFields),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showMoreCustomerFields ? 'Hide additional customer details' : '+ Add more customer details (Address, Aadhaar, etc.)',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                            ),
                            Icon(
                              _showMoreCustomerFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMoreCustomerFields) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _fatherNameController,
                        decoration: const InputDecoration(
                          labelText: "Father / Husband Name",
                          prefixIcon: Icon(Icons.family_restroom_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
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
                    ],
                  ],
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
                      labelText: 'Loan Number',
                      hintText: 'Auto-suggested (e.g. LN-004)',
                      prefixIcon: Icon(Icons.numbers, size: 20),
                    ),
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
