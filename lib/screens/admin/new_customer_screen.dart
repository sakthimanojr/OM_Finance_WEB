import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../providers/customer_provider.dart';

class NewCustomerScreen extends ConsumerStatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  ConsumerState<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends ConsumerState<NewCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _fatherName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _occupation = TextEditingController();
  final _monthlyIncome = TextEditingController();
  final _guarantorName = TextEditingController();
  final _guarantorPhone = TextEditingController();
  final _password = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _autoSyncPassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_autoSyncPassword && _phone.text.trim().isNotEmpty) {
      _password.text = _phone.text.trim();
    }
  }

  @override
  void dispose() {
    _phone.removeListener(_onPhoneChanged);
    for (final c in [
      _name,
      _fatherName,
      _phone,
      _email,
      _address,
      _aadhaar,
      _pan,
      _occupation,
      _monthlyIncome,
      _guarantorName,
      _guarantorPhone,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final phoneVal = _phone.text.trim();
      final passwordVal = _password.text.trim().isNotEmpty ? _password.text.trim() : phoneVal;
      final service = ref.read(customerServiceProvider);
      final customer = await service.createCustomer({
        'name': _name.text.trim(),
        if (_fatherName.text.isNotEmpty) 'fatherName': _fatherName.text.trim(),
        'phone': phoneVal,
        if (_email.text.isNotEmpty) 'email': _email.text.trim(),
        if (_address.text.isNotEmpty) 'address': _address.text.trim(),
        if (_aadhaar.text.isNotEmpty) 'aadhaar': _aadhaar.text.trim(),
        if (_pan.text.isNotEmpty) 'pan': _pan.text.trim().toUpperCase(),
        if (_occupation.text.isNotEmpty) 'occupation': _occupation.text.trim(),
        if (_monthlyIncome.text.isNotEmpty) 'monthlyIncome': num.tryParse(_monthlyIncome.text),
        if (_guarantorName.text.isNotEmpty) 'guarantorName': _guarantorName.text.trim(),
        if (_guarantorPhone.text.isNotEmpty) 'guarantorPhone': _guarantorPhone.text.trim(),
        'password': passwordVal,
      });
      ref.invalidate(customerListProvider);
      if (mounted) {
        context.pop();
        context.push('/admin/customers/${customer.id}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('Personal Details'),
            _field(_name, 'Full Name *', validator: _requiredValidator),
            _field(_fatherName, "Father's Name"),
            _field(_phone, 'Phone Number *', keyboardType: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
            _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
            _field(_address, 'Address', maxLines: 2),
            const SizedBox(height: 12),
            _sectionLabel('KYC Details'),
            _field(_aadhaar, 'Aadhaar Number (12 digits)', keyboardType: TextInputType.number, maxLength: 12),
            _field(_pan, 'PAN Number'),
            const SizedBox(height: 12),
            _sectionLabel('Financial Details'),
            _field(_occupation, 'Occupation'),
            _field(_monthlyIncome, 'Monthly Income', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _sectionLabel('Guarantor'),
            _field(_guarantorName, 'Guarantor Name'),
            _field(_guarantorPhone, 'Guarantor Phone', keyboardType: TextInputType.phone, maxLength: 10),
            const SizedBox(height: 12),
            _sectionLabel('Customer App Login & Password'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Customer can log in to the Customer App using their Phone Number as username and this Password.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                onChanged: (val) {
                  if (_autoSyncPassword && val != _phone.text.trim()) {
                    setState(() => _autoSyncPassword = false);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Customer App Login Password *',
                  hintText: 'Default: Same as Mobile Number',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        tooltip: _obscurePassword ? 'Show Password' : 'Hide Password',
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _password.text = _phone.text.trim();
                            _autoSyncPassword = true;
                          });
                        },
                        child: const Text('Use Mobile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                validator: _passwordValidator,
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
              icon: Icons.person_add_outlined,
              child: const Text('Create Customer'),
            ),
            const SizedBox(height: 8),
            Text(
              'A document upload step for Aadhaar/PAN/photo is available from the customer profile after creation.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.primaryColor,
            letterSpacing: 0.1,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label, counterText: maxLength != null ? '' : null),
        validator: validator,
      ),
    );
  }

  String? _requiredValidator(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _phoneValidator(String? value) {
    if (value == null || value.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 6) return 'At least 6 characters';
    return null;
  }
}
