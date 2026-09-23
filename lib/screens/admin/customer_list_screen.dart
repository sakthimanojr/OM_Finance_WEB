import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/customer_provider.dart';

// Deterministic color palette for customer initials
final _avatarColors = [
  const Color(0xFF5C35C9), // indigo
  const Color(0xFF0D7A6E), // teal
  const Color(0xFFE53935), // red
  const Color(0xFF9B59B6), // purple
  const Color(0xFFFF9100), // orange
  const Color(0xFF1565C0), // blue
  const Color(0xFF2E7D32), // green
  const Color(0xFF6D4C41), // brown
];

Color _avatarColor(String name) {
  if (name.isEmpty) return AppTheme.primaryColor;
  return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
}

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key, this.status});
  final String? status;

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerStatusFilterProvider.notifier).state = widget.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          ref.watch(customerStatusFilterProvider) == 'ACTIVE'
              ? 'Active Customers'
              : (ref.watch(customerStatusFilterProvider) == 'CLOSED'
                  ? 'Closed Loan Customers'
                  : 'All Customers'),
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/customers/new'),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
        label: const Text(
          'New Customer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        shape: const StadiumBorder(),
        elevation: 4,
      ),
      body: Column(
        children: [
          // Filter Chips: All, Active, Closed
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterTab(
                    label: 'All Customers',
                    isSelected: ref.watch(customerStatusFilterProvider) == null,
                    onTap: () => ref.read(customerStatusFilterProvider.notifier).state = null,
                  ),
                  _FilterTab(
                    label: 'Active',
                    isSelected: ref.watch(customerStatusFilterProvider) == 'ACTIVE',
                    onTap: () => ref.read(customerStatusFilterProvider.notifier).state = 'ACTIVE',
                  ),
                  _FilterTab(
                    label: 'Closed Loans / Profiles',
                    isSelected: ref.watch(customerStatusFilterProvider) == 'CLOSED',
                    onTap: () => ref.read(customerStatusFilterProvider.notifier).state = 'CLOSED',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(customerSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) =>
                    ref.read(customerSearchQueryProvider.notifier).state = value,
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(customerListProvider)),
              data: (customers) {
                if (customers.isEmpty) {
                  return const EmptyStateView(
                      message: 'No customers found', icon: Icons.people_outline);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(customerListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final isClosedLoan = customer.status == 'CLOSED' ||
                          customer.loanStatus == 'CLOSED' ||
                          customer.loanStatus == 'COMPLETED';
                      final displayStatus = isClosedLoan
                          ? 'CLOSED'
                          : (customer.status == 'OVERDUE' ? 'OVERDUE' : 'ACTIVE');
                      final avatarColor = _avatarColor(customer.name);
                      final initials = customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context
                                .push('/admin/customers/${customer.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Avatar + Customer Full Name (+ Father's name) + Status Badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Avatar with initials
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              avatarColor,
                                              avatarColor.withValues(alpha: 0.75),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: avatarColor.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Customer Name & Father Name - Full width, never cramped
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.textDark,
                                                height: 1.2,
                                              ),
                                              maxLines: 2,
                                              softWrap: true,
                                            ),
                                            if (customer.fatherName != null &&
                                                customer.fatherName!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'S/o ${customer.fatherName!.trim()}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                          status: displayStatus, showEmoji: true),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Details Badges Row (Wrap ensures NO overflow and full visibility on mobile)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // Loan Number Badge
                                      if (customer.loanNumber != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: isClosedLoan
                                                ? Colors.grey.shade100
                                                : AppTheme.primaryColor.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isClosedLoan
                                                  ? Colors.grey.shade300
                                                  : AppTheme.primaryColor.withValues(alpha: 0.30),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.receipt_long_outlined,
                                                size: 13,
                                                color: isClosedLoan
                                                    ? Colors.grey.shade700
                                                    : AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isClosedLoan
                                                    ? 'Loan #${customer.loanNumber} (Closed)'
                                                    : 'Loan #${customer.loanNumber}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isClosedLoan
                                                      ? Colors.grey.shade700
                                                      : AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.money_off_outlined,
                                                  size: 13,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                'No Active Loan',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Phone Number Badge
                                      if (customer.phone.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.phone_outlined,
                                                  size: 12,
                                                  color: AppTheme.primaryColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                customer.phone,
                                                style: const TextStyle(
                                                  color: AppTheme.textDark,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Address Badge if available
                                      if (customer.address != null &&
                                          customer.address!.trim().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.location_on_outlined,
                                                  size: 12,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 160),
                                                child: Text(
                                                  customer.address!.trim(),
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
