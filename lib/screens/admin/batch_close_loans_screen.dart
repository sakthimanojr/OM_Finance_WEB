import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/profile_color.dart';
import '../../core/widgets/state_views.dart';
import '../../models/loan_model.dart';
import '../../providers/closed_loan_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/loan_provider.dart';

class BatchCloseLoansScreen extends ConsumerStatefulWidget {
  const BatchCloseLoansScreen({super.key});

  @override
  ConsumerState<BatchCloseLoansScreen> createState() => _BatchCloseLoansScreenState();
}

class _BatchCloseLoansScreenState extends ConsumerState<BatchCloseLoansScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedLoanIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  num _calculatePendingAmount(Loan loan) {
    if (loan.dues.isNotEmpty) {
      final pendingDues = loan.dues.where((d) => d.status != 'PAID');
      return pendingDues.fold<num>(
        0,
        (sum, d) => sum + (d.amount - (d.paidAmount ?? 0)),
      );
    }
    // Fallback if dues not populated
    return loan.principal;
  }

  int _calculatePendingDuesCount(Loan loan) {
    return loan.dues.where((d) => d.status != 'PAID').length;
  }

  Future<void> _closeLoans(List<Loan> loansToClose) async {
    if (loansToClose.isEmpty) return;

    final totalAmount = loansToClose.fold<num>(
      0,
      (sum, l) => sum + _calculatePendingAmount(l),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Close Loans via Bank?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to close ${loansToClose.length} loan(s).',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        Formatters.currency(totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BANK_TRANSFER',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Settlement Date:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        Formatters.date(DateTime.now()),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• All pending dues will be marked as PAID today.\n• The full amount will be credited into Cash in Account in your Daily Daybook.\n• The loans will be marked as CLOSED.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            child: const Text('Confirm & Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(loanServiceProvider);
      final ids = loansToClose.map((l) => l.id).toList();
      final result = await service.batchCloseLoans(
        loanIds: ids,
        paymentMethod: 'BANK_TRANSFER',
        paidAt: DateTime.now(),
        remarks: 'Batch closed by admin via Bank Transfer',
      );

      // Invalidate relevant providers to update the UI everywhere
      ref.invalidate(adminLoanListProvider);
      ref.invalidate(customerListProvider);
      ref.invalidate(closedLoanListProvider);

      setState(() {
        _selectedLoanIds.removeAll(ids);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Closed ${result['closedCount']} loan(s) • Total ${Formatters.currency(result['totalAmountSettled'])} added to Account!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to close loans: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(adminLoanListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Batch Close Loans',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: loansAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (allLoans) {
          // Filter to active loans only
          final activeLoans = allLoans.where((l) => l.status != 'CLOSED' && l.status != 'COMPLETED').toList();

          final query = _searchController.text.trim().toLowerCase();
          final filteredLoans = activeLoans.where((l) {
            if (query.isEmpty) return true;
            final name = (l.customerName ?? '').toLowerCase();
            final phone = (l.customerPhone ?? '').toLowerCase();
            final num = (l.loanNumber ?? '').toLowerCase();
            return name.contains(query) || phone.contains(query) || num.contains(query);
          }).toList();

          final selectedLoans = activeLoans.where((l) => _selectedLoanIds.contains(l.id)).toList();
          final selectedTotal = selectedLoans.fold<num>(
            0,
            (sum, l) => sum + _calculatePendingAmount(l),
          );

          if (activeLoans.isEmpty) {
            return const EmptyStateView(
              title: 'No Active Loans',
              message: 'All loans are already closed or completed.',
              icon: Icons.check_circle_outline,
            );
          }

          return Column(
            children: [
              // Settlement Mode & Explanation Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.indigo.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settle Today via Bank Transfer',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toggle checkboxes to select loans. Upon closure, all remaining dues will be paid today via Bank Transfer and credited to Cash in Account.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar + Select All Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search borrower, phone, or loan #...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() => _searchController.clear()),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedLoanIds.length == filteredLoans.length) {
                            _selectedLoanIds.clear();
                          } else {
                            _selectedLoanIds.addAll(filteredLoans.map((l) => l.id));
                          }
                        });
                      },
                      icon: Icon(
                        _selectedLoanIds.length == filteredLoans.length && filteredLoans.isNotEmpty
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        _selectedLoanIds.length == filteredLoans.length && filteredLoans.isNotEmpty
                            ? 'Deselect'
                            : 'Select All',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Active Loans Count & Selection Info Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Showing ${filteredLoans.length} active loan${filteredLoans.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (_selectedLoanIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedLoanIds.length} Selected',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Loan Cards List
              Expanded(
                child: filteredLoans.isEmpty
                    ? const Center(child: Text('No matching loans found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filteredLoans.length,
                        itemBuilder: (context, index) {
                          final loan = filteredLoans[index];
                          final isSelected = _selectedLoanIds.contains(loan.id);
                          final pendingAmt = _calculatePendingAmount(loan);
                          final pendingCount = _calculatePendingDuesCount(loan);
                          final dayColor = ProfileDayColor.forDateTime(loan.startDate);
                          final dayName = ProfileDayColor.dayName(loan.startDate);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedLoanIds.remove(loan.id);
                                  } else {
                                    _selectedLoanIds.add(loan.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedLoanIds.add(loan.id);
                                          } else {
                                            _selectedLoanIds.remove(loan.id);
                                          }
                                        });
                                      },
                                    ),

                                    // Day Color Avatar
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: dayColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: dayColor.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          (loan.customerName ?? '?').isNotEmpty
                                              ? (loan.customerName ?? '?')[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Borrower & Loan Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  loan.customerName ?? 'Borrower',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppTheme.textDark,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Day Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: dayColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: dayColor.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  dayName,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: dayColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (loan.loanNumber != null) ...[
                                                Text(
                                                  'Loan #${loan.loanNumber}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                                const Text(' • ', style: TextStyle(color: Colors.grey)),
                                              ],
                                              if (loan.customerPhone != null && loan.customerPhone!.isNotEmpty)
                                                Text(
                                                  loan.customerPhone!,
                                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Pending Settlement Amount
                                          Row(
                                            children: [
                                              Text(
                                                'Pending: ${Formatters.currency(pendingAmt)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.errorColor,
                                                ),
                                              ),
                                              if (pendingCount > 0)
                                                Text(
                                                  ' ($pendingCount due${pendingCount == 1 ? '' : 's'})',
                                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quick Single Close Action
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                                      tooltip: 'Close this loan now',
                                      onPressed: _isSubmitting ? null : () => _closeLoans([loan]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      // Sticky Bottom Bar when loans are selected
      bottomSheet: _selectedLoanIds.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: loansAsync.maybeWhen(
                  data: (allLoans) {
                    final selectedLoans = allLoans.where((l) => _selectedLoanIds.contains(l.id)).toList();
                    final selectedTotal = selectedLoans.fold<num>(
                      0,
                      (sum, l) => sum + _calculatePendingAmount(l),
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedLoans.length} Loan${selectedLoans.length == 1 ? '' : 's'} Selected',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Total: ${Formatters.currency(selectedTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : () => _closeLoans(selectedLoans),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.account_balance, size: 18),
                          label: Text(
                            _isSubmitting ? 'Closing...' : 'Close Selected (${selectedLoans.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),
    );
  }
}
