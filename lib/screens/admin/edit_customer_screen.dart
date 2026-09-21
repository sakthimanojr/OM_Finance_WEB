import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../services/customer_service.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  const EditCustomerScreen({super.key, required this.customer});
  final Customer customer;

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _monthlyIncomeCtrl;
  late final TextEditingController _guarantorNameCtrl;
  late final TextEditingController _guarantorPhoneCtrl;
  late final TextEditingController _emergencyContactCtrl;
  String _status = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email ?? '');
    _fatherNameCtrl = TextEditingController(text: c.fatherName ?? '');
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _occupationCtrl = TextEditingController(text: c.occupation ?? '');
    _monthlyIncomeCtrl = TextEditingController(
        text: c.monthlyIncome != null ? c.monthlyIncome.toString() : '');
    _guarantorNameCtrl = TextEditingController(text: c.guarantorName ?? '');
    _guarantorPhoneCtrl = TextEditingController(text: c.guarantorPhone ?? '');
    _emergencyContactCtrl =
        TextEditingController(text: c.emergencyContact ?? '');
    _status = c.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _fatherNameCtrl.dispose();
    _addressCtrl.dispose();
    _occupationCtrl.dispose();
    _monthlyIncomeCtrl.dispose();
    _guarantorNameCtrl.dispose();
    _guarantorPhoneCtrl.dispose();
    _emergencyContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'status': _status,
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_fatherNameCtrl.text.trim().isNotEmpty)
        'fatherName': _fatherNameCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_occupationCtrl.text.trim().isNotEmpty)
        'occupation': _occupationCtrl.text.trim(),
      if (_monthlyIncomeCtrl.text.trim().isNotEmpty)
        'monthlyIncome':
            num.tryParse(_monthlyIncomeCtrl.text.trim()),
      if (_guarantorNameCtrl.text.trim().isNotEmpty)
        'guarantorName': _guarantorNameCtrl.text.trim(),
      if (_guarantorPhoneCtrl.text.trim().isNotEmpty)
        'guarantorPhone': _guarantorPhoneCtrl.text.trim(),
      if (_emergencyContactCtrl.text.trim().isNotEmpty)
        'emergencyContact': _emergencyContactCtrl.text.trim(),
    };

    try {
      await CustomerService().updateCustomer(widget.customer.id, payload);

      // Invalidate providers so detail screen refreshes
      ref.invalidate(customerDetailProvider(widget.customer.id));
      ref.invalidate(customerListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successColor,
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Customer updated successfully!'),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(true); // return true = updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('Update failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Edit Customer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              label: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Basic Information', [
              _field(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              _field(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  if (v.trim().length != 10) return 'Enter a valid 10-digit phone';
                  return null;
                },
              ),
              _field(
                controller: _emailCtrl,
                label: 'Email (optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ]),
            const SizedBox(height: 16),
            _section('Personal Details', [
              _field(
                controller: _fatherNameCtrl,
                label: "Father's Name",
                icon: Icons.family_restroom_outlined,
              ),
              _field(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
              _field(
                controller: _occupationCtrl,
                label: 'Occupation',
                icon: Icons.work_outline,
              ),
              _field(
                controller: _monthlyIncomeCtrl,
                label: 'Monthly Income (₹)',
                icon: Icons.currency_rupee,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('Emergency & Guarantor', [
              _field(
                controller: _guarantorNameCtrl,
                label: 'Guarantor Name',
                icon: Icons.shield_outlined,
              ),
              _field(
                controller: _guarantorPhoneCtrl,
                label: 'Guarantor Phone',
                icon: Icons.phone_forwarded_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _field(
                controller: _emergencyContactCtrl,
                label: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
              ),
            ]),
            const SizedBox(height: 16),
            _section('Account Status', [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Status',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _loading ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...children.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: w,
              )),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
