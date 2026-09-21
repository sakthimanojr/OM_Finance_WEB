import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider((ref) => DashboardService());

final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getAdminSummary();
});

final customerSummaryProvider = FutureProvider.autoDispose<CustomerSummary>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getCustomerSummary();
});
