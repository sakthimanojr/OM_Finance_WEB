import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/customer_provider.dart';
import '../../providers/loan_provider.dart';
import '../shared/documents_section.dart';
import 'edit_customer_screen.dart';
import 'edit_loan_dialog.dart';


class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final loansAsync = ref.watch(loanListProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          customerAsync.maybeWhen(
            data: (customer) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Customer',
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditCustomerScreen(customer: customer),
                      ),
                    );
                    if (updated == true) {
                      ref.invalidate(customerDetailProvider(customerId));
                      ref.invalidate(loanListProvider(customerId));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notification History',
                  onPressed: () => context.push(
                      '/admin/customers/$customerId/notifications?name=${Uri.encodeComponent(customer.name)}'),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/loans/new?customerId=$customerId'),
        icon: const Icon(Icons.add),
        label: const Text('New Loan'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: customerAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (customer) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customerDetailProvider(customerId));
            ref.invalidate(loanListProvider(customerId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium profile header card
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customer.phone,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  customer.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personal info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.person_outline,
                            color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                    const Divider(height: 24),
                    if (customer.email == null &&
                        customer.fatherName == null &&
                        customer.address == null &&
                        customer.aadhaarLast4 == null &&
                        customer.pan == null &&
                        customer.occupation == null &&
                        customer.monthlyIncome == null &&
                        customer.guarantorName == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'No additional information available',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    if (customer.email != null)
                      _infoRow('Email', customer.email!),
                    if (customer.fatherName != null)
                      _infoRow("Father's Name", customer.fatherName!),
                    if (customer.address != null)
                      _infoRow('Address', customer.address!),
                    if (customer.aadhaarLast4 != null)
                      _infoRow(
                          'Aadhaar', 'XXXX XXXX ${customer.aadhaarLast4}'),
                    if (customer.pan != null) _infoRow('PAN', customer.pan!),
                    if (customer.occupation != null)
                      _infoRow('Occupation', customer.occupation!),
                    if (customer.monthlyIncome != null)
                      _infoRow('Monthly Income',
                          Formatters.currency(customer.monthlyIncome)),
                    if (customer.guarantorName != null)
                      _infoRow('Guarantor', customer.guarantorName!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DocumentsSection(customerId: customer.id),
              const SizedBox(height: 24),

              // Loan History section
              Row(
                children: [
                  const Text(
                    'Loan History',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                  ),
                  const Spacer(),
                  Icon(Icons.history,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              loansAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(16), child: LoadingView()),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (loans) {
                  if (loans.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyStateView(
                        message: 'No loans yet',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    );
                  }
                  return Column(
                    children: loans
                        .map(
                          (loan) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              title: Text(
                                '${loan.loanNumber != null ? 'Loan #${loan.loanNumber} • ' : ''}'
                                '${loan.type.replaceAll('_', ' ')} • ${Formatters.currency(loan.principal)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                              subtitle: Text(
                                'Started ${Formatters.date(loan.startDate)}',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(status: loan.status),
                                  if (loan.status != 'CLOSED' && loan.status != 'COMPLETED') ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                                      tooltip: 'Edit Loan Amount',
                                      onPressed: () async {
                                        final updated = await EditLoanDialog.show(context, loan);
                                        if (updated == true) {
                                          ref.invalidate(customerDetailProvider(customerId));
                                          ref.invalidate(loanListProvider(customerId));
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () => context
                                  .push('/admin/loans/${loan.id}'),
                            ),
                          ),
                        )
                        .toList(),
                  );

                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
