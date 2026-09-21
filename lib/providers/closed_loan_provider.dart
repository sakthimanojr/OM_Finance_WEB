import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/closed_loan_model.dart';
import '../services/closed_loan_service.dart';

final closedLoanServiceProvider = Provider((ref) => ClosedLoanService());

final closedLoanListProvider = FutureProvider.autoDispose<List<ClosedLoan>>((ref) async {
  final service = ref.watch(closedLoanServiceProvider);
  return service.listClosedLoans();
});

final closedLoanDetailProvider =
    FutureProvider.autoDispose.family<ClosedLoan, String>((ref, id) async {
  final service = ref.watch(closedLoanServiceProvider);
  return service.getClosedLoan(id);
});
