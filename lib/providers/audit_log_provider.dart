import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log_model.dart';
import '../services/audit_log_service.dart';

final auditLogServiceProvider = Provider((ref) => AuditLogService());

final auditLogFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final auditLogPaymentMethodFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final auditLogListProvider = FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final service = ref.watch(auditLogServiceProvider);
  final entityType = ref.watch(auditLogFilterProvider);
  final paymentMethod = ref.watch(auditLogPaymentMethodFilterProvider);
  return service.listAuditLogs(entityType: entityType, paymentMethod: paymentMethod);
});
