import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

final loanServiceProvider = Provider((ref) => LoanService());

final loanListProvider =
    FutureProvider.autoDispose.family<List<Loan>, String?>((ref, customerId) async {
  final service = ref.watch(loanServiceProvider);
  return service.listLoans(customerId: customerId);
});

final loanStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final adminLoanListProvider = FutureProvider.autoDispose<List<Loan>>((ref) async {
  final service = ref.watch(loanServiceProvider);
  final status = ref.watch(loanStatusFilterProvider);
  return service.listLoans(status: status);
});

final loanDetailProvider = FutureProvider.autoDispose.family<Loan, String>((ref, id) async {
  final service = ref.watch(loanServiceProvider);
  return service.getLoan(id);
});
