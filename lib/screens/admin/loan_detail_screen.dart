import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/loan_provider.dart';
import '../../services/payment_service.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailProvider(loanId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Loan Details', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: loanAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(loanDetailProvider(loanId))),
        data: (loan) => RefreshIndicator(
          onRefresh: () async => ref.refresh(loanDetailProvider(loanId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium loan header card
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withOpacity(0.35),
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
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.type.replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    if (loan.loanNumber != null)
                                      Text(
                                        'Loan #${loan.loanNumber}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.w600,
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
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  loan.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (loan.customerName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              loan.customerName!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _WhiteStatCol('Principal',
                                  Formatters.currency(loan.principal)),
                              _WhiteStatCol('Collected',
                                  Formatters.currency(loan.totalCollection)),
                              _WhiteStatCol('Outstanding',
                                  Formatters.currency(loan.outstandingAmount)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loan details card
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        const Text(
                          'Loan Breakdown',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.receipt_long_outlined,
                            color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                    const Divider(height: 24),
                    _DetailRow('Disbursed Amount',
                        Formatters.currency(loan.disbursedAmount)),
                    _DetailRow(
                        'Interest Rate', '${loan.interestRate}%',
                        valueColor: AppTheme.accentColor),
                    _DetailRow('Start Date', Formatters.date(loan.startDate)),
                    if (loan.endDate != null)
                      _DetailRow('End Date', Formatters.date(loan.endDate)),
                  ],
                ),
              ),

              if (loan.type == AppConstants.loanHighValue &&
                  loan.status != 'COMPLETED' &&
                  loan.status != 'CLOSED') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showRepayPrincipalDialog(
                          context, ref, loan.id, loan.outstandingAmount),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payments_outlined,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Record Principal Repayment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Due schedule header
              Row(
                children: [
                  const Text(
                    'Due Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${loan.dues.where((d) => d.status == 'PAID').length}/${loan.dues.length} paid',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: loan.dues.isEmpty
                      ? 0
                      : loan.dues
                              .where((d) => d.status == 'PAID')
                              .length /
                          loan.dues.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.successColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              ...loan.dues.map(
                (due) {
                  final isPaid = due.status == 'PAID';
                  final isOverdue = due.status == 'OVERDUE';
                  final borderColor = isPaid
                      ? AppTheme.successColor.withOpacity(0.3)
                      : isOverdue
                          ? AppTheme.errorColor.withOpacity(0.3)
                          : Colors.grey.shade100;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isPaid
                            ? AppTheme.successColor.withOpacity(0.1)
                            : isOverdue
                                ? AppTheme.errorColor.withOpacity(0.1)
                                : Colors.grey.shade100,
                        child: Text(
                          '${due.dueNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppTheme.successColor
                                : isOverdue
                                    ? AppTheme.errorColor
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      title: Text(
                        Formatters.currency(due.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due ${Formatters.date(due.dueDate)}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                          if (due.status == 'PAID' && due.paidDate != null)
                            Text(
                              'Paid on ${Formatters.dateTime(due.paidDate!)}',
                              style: TextStyle(
                                  color: AppTheme.successColor, fontSize: 11),
                            ),
                        ],
                      ),
                      trailing: StatusBadge(status: due.status),
                      onTap: due.status == 'PAID'
                          ? null
                          : () => _showCollectPaymentSheet(
                              context,
                              ref,
                              loanId,
                              due.id,
                              due.amount,
                              due.dueNumber),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepayPrincipalDialog(
      BuildContext context, WidgetRef ref, String loanId, num maxAmount) {
    final controller = TextEditingController();
    String method = 'CASH';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Record Principal Repayment',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding: ${Formatters.currency(maxAmount)}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                ],
                onChanged: (value) =>
                    setDialogState(() => method = value ?? 'CASH'),
                decoration: const InputDecoration(labelText: 'Method'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = num.tryParse(controller.text);
                if (amount == null || amount <= 0) return;
                try {
                  await ref
                      .read(loanServiceProvider)
                      .repayPrincipal(loanId, amount, method);
                  ref.invalidate(loanDetailProvider(loanId));
                  if (context.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.errorColor));
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectPaymentSheet(
    BuildContext context,
    WidgetRef ref,
    String loanId,
    String dueId,
    num amount,
    int dueNumber,
  ) {
    String method = 'CASH';
    final refController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Collect Payment — Due #$dueNumber',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      Formatters.currency(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                ],
                onChanged: (value) =>
                    setSheetState(() => method = value ?? 'CASH'),
                decoration:
                    const InputDecoration(labelText: 'Payment Method'),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isProcessing
                        ? null
                        : () async {
                            setSheetState(() => isProcessing = true);
                            try {
                              final paymentService = PaymentService();
                              final initiated =
                                  await paymentService.initiatePayment(
                                dueId: dueId,
                                method: method,
                                amount: amount,
                              );
                              final confirmed =
                                  await paymentService.confirmPayment(
                                initiated.payment.id,
                                upiRefNumber:
                                    refController.text.isNotEmpty
                                        ? refController.text
                                        : null,
                              );
                              ref.invalidate(loanDetailProvider(loanId));
                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Payment Confirmed! Bill No: ${confirmed.billNumber ?? "N/A"} (Receipt: ${confirmed.receiptNumber ?? "N/A"})'),
                                    backgroundColor: AppTheme.successColor,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isProcessing = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor:
                                            AppTheme.errorColor));
                              }
                            }
                          },
                    child: Center(
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Confirm Payment Received',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteStatCol extends StatelessWidget {
  const _WhiteStatCol(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
