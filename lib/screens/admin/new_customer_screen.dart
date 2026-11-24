import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/customer_provider.dart';
import 'customer_form_widget.dart';

class NewCustomerScreen extends ConsumerStatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  ConsumerState<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends ConsumerState<NewCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = CustomerFormControllers();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final c = _controllers;
      final phoneVal = c.phone.text.trim();
      // If password is blank or still equals phone, default to phone.
      final passwordVal = c.password.text.trim().isNotEmpty
          ? c.password.text.trim()
          : phoneVal;

      final service = ref.read(customerServiceProvider);
      final customer = await service.createCustomer({
        'name': c.name.text.trim(),
        if (c.fatherName.text.trim().isNotEmpty)
          'fatherName': c.fatherName.text.trim(),
        'phone': phoneVal,
        if (c.email.text.trim().isNotEmpty) 'email': c.email.text.trim(),
        if (c.address.text.trim().isNotEmpty) 'address': c.address.text.trim(),
        if (c.aadhaar.text.trim().isNotEmpty) 'aadhaar': c.aadhaar.text.trim(),
        if (c.pan.text.trim().isNotEmpty)
          'pan': c.pan.text.trim().toUpperCase(),
        if (c.occupation.text.trim().isNotEmpty)
          'occupation': c.occupation.text.trim(),
        if (c.monthlyIncome.text.trim().isNotEmpty)
          'monthlyIncome': num.tryParse(c.monthlyIncome.text.trim()),
        if (c.emergencyContact.text.trim().isNotEmpty)
          'emergencyContact': c.emergencyContact.text.trim(),
        if (c.guarantorName.text.trim().isNotEmpty)
          'guarantorName': c.guarantorName.text.trim(),
        if (c.guarantorPhone.text.trim().isNotEmpty)
          'guarantorPhone': c.guarantorPhone.text.trim(),
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
        title: const Text('New Customer'),
      ),
      body: Stack(
        children: [
          CustomerFormWidget(
            formKey: _formKey,
            controllers: _controllers,
            isEditMode: false,
            isLoading: _isSubmitting,
            onSubmit: _submit,
          ),
          // Error banner
          if (_error != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: AppTheme.errorColor,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
