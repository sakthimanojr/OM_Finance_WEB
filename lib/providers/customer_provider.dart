import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

final customerServiceProvider = Provider((ref) => CustomerService());

final customerSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final customerStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final customerListProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final service = ref.watch(customerServiceProvider);
  final search = ref.watch(customerSearchQueryProvider);
  final status = ref.watch(customerStatusFilterProvider);
  return service.listCustomers(search: search, status: status);
});

final myProfileProvider = FutureProvider.autoDispose<Customer>((ref) async {
  final service = ref.watch(customerServiceProvider);
  return service.getMyProfile();
});

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer, String>((ref, id) async {
  final service = ref.watch(customerServiceProvider);
  return service.getCustomer(id);
});
