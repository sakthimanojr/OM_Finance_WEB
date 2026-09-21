import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chit_fund_model.dart';
import '../models/chit_auction_model.dart';
import '../models/chit_loan_model.dart';
import '../services/chit_fund_service.dart';

final chitFundServiceProvider = Provider((ref) => ChitFundService());

// ─── Admin: Chit Fund List ────────────────────────────────────────────────────

final chitFundListProvider = FutureProvider.autoDispose<List<ChitFund>>((ref) async {
  return ref.watch(chitFundServiceProvider).listChitFunds();
});

final chitFundDetailProvider =
    FutureProvider.autoDispose.family<ChitFund, String>((ref, id) async {
  return ref.watch(chitFundServiceProvider).getChitFund(id);
});

// ─── Admin: Members ───────────────────────────────────────────────────────────

final chitMemberListProvider =
    FutureProvider.autoDispose.family<List<ChitMember>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).listMembers(chitId);
});

// ─── Admin: Months ────────────────────────────────────────────────────────────

final chitMonthListProvider =
    FutureProvider.autoDispose.family<List<ChitMonth>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).listMonths(chitId);
});

// ─── Admin: Auctions ──────────────────────────────────────────────────────────

final chitAuctionListProvider =
    FutureProvider.autoDispose.family<List<ChitAuction>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).listAuctions(chitId);
});

// ─── Admin: Member Payments ───────────────────────────────────────────────────

final chitPaymentListProvider =
    FutureProvider.autoDispose.family<List<ChitMemberPayment>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).listPayments(chitId);
});

// ─── Admin: Loans ──────────────────────────────────────────────────────────────

final chitLoanListProvider =
    FutureProvider.autoDispose.family<List<ChitLoan>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).listLoans(chitId);
});

final chitLoanDetailProvider =
    FutureProvider.autoDispose.family<ChitLoan, String>((ref, loanId) async {
  return ref.watch(chitFundServiceProvider).getLoan(loanId);
});

// ─── Admin: Fund Summary ──────────────────────────────────────────────────────

final chitFundSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getFundSummary(chitId);
});

final chitLedgerProvider =
    FutureProvider.autoDispose.family<List<ChitFundLedger>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getLedger(chitId);
});

// ─── Admin: Reports ───────────────────────────────────────────────────────────

final chitSummaryReportProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getSummaryReport(chitId);
});

// ─── Customer: My Chits ───────────────────────────────────────────────────────

final myChitListProvider = FutureProvider.autoDispose<List<ChitMember>>((ref) async {
  return ref.watch(chitFundServiceProvider).listMyChits();
});

final myChitDetailProvider =
    FutureProvider.autoDispose.family<ChitMember, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getMyChit(chitId);
});

final myChitPaymentsProvider =
    FutureProvider.autoDispose.family<List<ChitMemberPayment>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getMyPayments(chitId);
});

final myChitAuctionsProvider =
    FutureProvider.autoDispose.family<List<ChitAuction>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getMyAuctions(chitId);
});

final myChitLoansProvider =
    FutureProvider.autoDispose.family<List<ChitLoan>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getMyLoans(chitId);
});

final myChitLoanDetailProvider =
    FutureProvider.autoDispose.family<ChitLoan, ({String chitId, String loanId})>((ref, p) async {
  return ref.watch(chitFundServiceProvider).getMyLoanDetail(p.chitId, p.loanId);
});

final myChitLedgerProvider =
    FutureProvider.autoDispose.family<List<ChitFundLedger>, String>((ref, chitId) async {
  return ref.watch(chitFundServiceProvider).getMyLedger(chitId);
});
