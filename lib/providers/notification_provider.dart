import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_history_service.dart';

final notificationHistoryServiceProvider = Provider((ref) => NotificationHistoryService());

final customerNotificationsProvider =
    FutureProvider.autoDispose.family<List<AppNotification>, String>((ref, customerId) async {
  final service = ref.watch(notificationHistoryServiceProvider);
  return service.listForCustomer(customerId);
});
