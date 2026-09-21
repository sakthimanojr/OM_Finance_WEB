import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/customer_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(myProfileProvider)),
        data: (customer) => RefreshIndicator(
          onRefresh: () async => ref.refresh(myProfileProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Center(
                child: Text(customer.status, style: TextStyle(color: AppTheme.statusColor(customer.status))),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Phone', customer.phone),
                      if (customer.email != null) _row('Email', customer.email!),
                      if (customer.fatherName != null) _row("Father's Name", customer.fatherName!),
                      if (customer.address != null) _row('Address', customer.address!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KYC Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (customer.aadhaarLast4 != null) _row('Aadhaar', 'XXXX XXXX ${customer.aadhaarLast4}'),
                      if (customer.pan != null) _row('PAN', customer.pan!),
                      if (customer.occupation != null) _row('Occupation', customer.occupation!),
                      if (customer.monthlyIncome != null)
                        _row('Monthly Income', Formatters.currency(customer.monthlyIncome)),
                    ],
                  ),
                ),
              ),
              if (customer.guarantorName != null || customer.emergencyContact != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Guarantor / Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (customer.guarantorName != null) _row('Guarantor', customer.guarantorName!),
                        if (customer.guarantorPhone != null) _row('Guarantor Phone', customer.guarantorPhone!),
                        if (customer.emergencyContact != null) _row('Emergency Contact', customer.emergencyContact!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'To update any of these details, please contact your loan officer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
