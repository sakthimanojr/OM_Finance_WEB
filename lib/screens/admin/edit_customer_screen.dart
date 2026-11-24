import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../services/customer_service.dart';
import 'customer_form_widget.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  const EditCustomerScreen({super.key, required this.customer});
  final Customer customer;

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = CustomerFormControllers();

  bool _loading = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _controllers.populateFrom(widget.customer);
    _status = widget.customer.status;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final c = _controllers;
    final payload = <String, dynamic>{
      'name': c.name.text.trim(),
      'phone': c.phone.text.trim(),
      'status': _status,
      if (c.password.text.trim().isNotEmpty)
        'password': c.password.text.trim(),
      if (c.email.text.trim().isNotEmpty) 'email': c.email.text.trim(),
      if (c.fatherName.text.trim().isNotEmpty)
        'fatherName': c.fatherName.text.trim(),
      if (c.address.text.trim().isNotEmpty) 'address': c.address.text.trim(),
      if (c.aadhaar.text.trim().isNotEmpty) 'aadhaar': c.aadhaar.text.trim(),
      if (c.pan.text.trim().isNotEmpty) 'pan': c.pan.text.trim().toUpperCase(),
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
    };

    try {
      await CustomerService().updateCustomer(widget.customer.id, payload);

      // Invalidate providers so detail screen refreshes automatically.
      ref.invalidate(customerDetailProvider(widget.customer.id));
      ref.invalidate(customerListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successColor,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Customer updated successfully!'),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(true); // true = updated
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
        title: const Text('Edit Customer'),
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
              label: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: CustomerFormWidget(
        formKey: _formKey,
        controllers: _controllers,
        isEditMode: true,
        isLoading: _loading,
        onSubmit: _save,
        currentPhone: widget.customer.phone,
        currentStatus: _status,
        onStatusChanged: (v) => setState(() => _status = v),
      ),
    );
  }
}
