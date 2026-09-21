import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/due_model.dart';
import '../services/due_service.dart';

final dueServiceProvider = Provider((ref) => DueService());

final upcomingDuesProvider = FutureProvider.autoDispose<List<Due>>((ref) async {
  final service = ref.watch(dueServiceProvider);
  return service.getUpcoming(days: 7);
});

final overdueDuesProvider = FutureProvider.autoDispose<List<Due>>((ref) async {
  final service = ref.watch(dueServiceProvider);
  return service.getOverdue();
});

final todaysDuesProvider = FutureProvider.autoDispose<List<Due>>((ref) async {
  final service = ref.watch(dueServiceProvider);
  return service.getTodaysDues();
});

final duesByCustomerProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(dueServiceProvider);
  return service.getDuesByCustomer();
});

final customerDuesProvider =
    FutureProvider.autoDispose.family<List<Due>, String>((ref, customerId) async {
  final service = ref.watch(dueServiceProvider);
  return service.listDues(customerId: customerId);
});

