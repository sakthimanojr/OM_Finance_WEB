import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../services/receipt_service.dart';

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  final _paymentService = PaymentService();
  final _receiptService = ReceiptService();

  late Future<List<Payment>> _paymentsFuture;
  String? _downloadingPaymentId;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _paymentService.listPayments();
  }

  Future<void> _refresh() async {
    setState(() => _paymentsFuture = _paymentService.listPayments());
    await _paymentsFuture;
  }

  Future<void> _downloadReceipt(Payment payment) async {
    if (payment.receiptId == null) return;
    setState(() => _downloadingPaymentId = payment.id);
    try {
      final dir = await getTemporaryDirectory();
      final filename = '${payment.receiptNumber ?? payment.id}.pdf';
      final savePath = '${dir.path}/$filename';
      await _receiptService.downloadPdf(payment.receiptId!, savePath);
      await OpenFilex.open(savePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _downloadingPaymentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My Payments', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Payment>>(
          future: _paymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snapshot.hasError) {
              return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
            }
            final payments = snapshot.data ?? [];
            if (payments.isEmpty) {
              return const EmptyStateView(message: 'No payments yet', icon: Icons.receipt_long_outlined);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final isDownloading = _downloadingPaymentId == payment.id;
                final hasReceipt = payment.status == 'SUCCESS' && payment.receiptId != null;
                return Container(
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
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_outlined, color: AppTheme.primaryColor, size: 18),
                    ),
                    title: Text(
                      Formatters.currency(payment.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark),
                    ),
                    subtitle: Text(
                      '${payment.method} · ${payment.paidAt != null ? Formatters.dateTime(payment.paidAt) : 'Pending'}'
                      '${payment.billNumber != null ? '\nBill: ${payment.billNumber} · Receipt: ${payment.receiptNumber}' : (payment.receiptNumber != null ? '\nReceipt: ${payment.receiptNumber}' : '')}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    isThreeLine: payment.receiptNumber != null || payment.billNumber != null,
                    trailing: hasReceipt
                        ? (isDownloading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.download_outlined, color: AppTheme.primaryColor),
                                onPressed: () => _downloadReceipt(payment),
                              ))
                        : StatusBadge(status: payment.status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
