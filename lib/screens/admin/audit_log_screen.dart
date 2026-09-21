import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/audit_log_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  static const _entityTypes = ['Customer', 'Loan', 'Payment', 'Document', 'User', 'AdminConfig', 'Notification'];

  IconData _iconForAction(String action) {
    if (action.contains('CREATE')) return Icons.add_circle_outline;
    if (action.contains('DELETE')) return Icons.delete_outline;
    if (action.contains('UPDATE') || action.contains('CONFIG')) return Icons.edit_outlined;
    if (action.contains('CONFIRM') || action.contains('PAYMENT')) return Icons.payments_outlined;
    if (action.contains('CLOSE')) return Icons.lock_outline;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogListProvider);
    final filter = ref.watch(auditLogFilterProvider);
    final paymentFilter = ref.watch(auditLogPaymentMethodFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Audit Log', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: filter == null,
                      onSelected: (_) => ref.read(auditLogFilterProvider.notifier).state = null,
                    ),
                  ),
                  ..._entityTypes.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: filter == type,
                        onSelected: (_) => ref.read(auditLogFilterProvider.notifier).state = type,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filter == 'Payment')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 12, top: 8),
                      child: Text('Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: paymentFilter == null,
                        onSelected: (_) => ref.read(auditLogPaymentMethodFilterProvider.notifier).state = null,
                      ),
                    ),
                    ...['CASH', 'UPI', 'MANUAL', 'BANK_TRANSFER'].map(
                      (method) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(method.replaceAll('_', ' ')),
                          selected: paymentFilter == method,
                          onSelected: (_) => ref.read(auditLogPaymentMethodFilterProvider.notifier).state = method,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: logsAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(auditLogListProvider)),
              data: (logs) {
                if (logs.isEmpty) {
                  return const EmptyStateView(message: 'No audit entries found', icon: Icons.history);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(auditLogListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Widget? trailing;
                      if (log.entityType == 'Payment' && log.details != null) {
                        final method = (log.details as Map<String, dynamic>)['method'] as String?;
                        if (method != null) {
                          Color badgeColor = AppTheme.textMuted;
                          if (method == 'CASH') badgeColor = AppTheme.successColor;
                          if (method == 'UPI') badgeColor = AppTheme.primaryColor;
                          if (method == 'MANUAL') badgeColor = AppTheme.warningColor;
                          if (method == 'BANK_TRANSFER') badgeColor = AppTheme.accentColor;

                          trailing = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              method.replaceAll('_', ' '),
                              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_iconForAction(log.action), color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(
                            log.action.replaceAll('_', ' '),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                          ),
                          subtitle: Text(
                            '${log.entityType}${log.entityId != null ? ' · ${log.entityId!.substring(0, 8)}…' : ''}\n'
                            'by ${log.adminPhone ?? log.adminId} · ${Formatters.dateTime(log.createdAt)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                          isThreeLine: true,
                          trailing: trailing,
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
