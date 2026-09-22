import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/payment_service.dart';
import '../../providers/dashboard_provider.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key, this.month});
  final String? month;

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  final _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = widget.month == 'current';
    final title = isCurrentMonth ? 'Monthly Collections' : 'Overall Collections';
    final summaryAsync = ref.watch(adminSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVERALL COLLECTED',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(summary.totalCollected),
                            style: const TextStyle(
                              color: AppTheme.accentLime,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL DISBURSED',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(summary.totalDisbursed),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final future = _paymentService.listPayments(month: widget.month);
                
                return FutureBuilder(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }
                    if (snapshot.hasError) {
                      return ErrorView(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(() {}),
                      );
                    }
                    
                    final payments = snapshot.data ?? [];
                    if (payments.isEmpty) {
                      return const EmptyStateView(
                        message: 'No collections found',
                        icon: Icons.payments_outlined,
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return GestureDetector(
                    onTap: () => context.push('/admin/customers/${payment.customerId}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.10),
                          child: const Icon(Icons.currency_rupee, color: AppTheme.primaryColor, size: 18),
                        ),
                        title: Text(
                          Formatters.currency(payment.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark),
                        ),
                        subtitle: Text(
                          '${payment.customerName ?? 'Unknown'} · ${payment.method.replaceAll('_', ' ')}\n'
                          '${payment.billNumber != null ? 'Bill No: ${payment.billNumber} · ' : ''}'
                          '${Formatters.dateTime(payment.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        isThreeLine: payment.billNumber != null,
                        trailing: StatusBadge(status: payment.status),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
  ],
),
);
}
}
