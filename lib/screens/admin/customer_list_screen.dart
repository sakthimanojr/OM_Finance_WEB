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
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/customers/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New Customer'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Builder(builder: (ctx) {
                            final avatarColor = _avatarColor(customer.name);
                            final initials = customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?';
                            return Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    avatarColor,
                                    avatarColor.withOpacity(0.7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: avatarColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
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
                            );
                          }),
                          title: Text(customer.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 11, color: AppTheme.textMuted),
                              const SizedBox(width: 3),
                              Text(customer.phone,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                          trailing: StatusBadge(
                              status: customer.status, showEmoji: true),
                          onTap: () => context
                              .push('/admin/customers/${customer.id}'),
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
