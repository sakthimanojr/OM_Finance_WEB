import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_model.dart';
import '../services/admin_management_service.dart';

final adminManagementServiceProvider = Provider((ref) => AdminManagementService());

final adminListProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) async {
  final service = ref.watch(adminManagementServiceProvider);
  return service.listAdmins();
});

final systemConfigProvider = FutureProvider.autoDispose<SystemConfig>((ref) async {
  final service = ref.watch(adminManagementServiceProvider);
  return service.getConfig();
});
