import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/chit_fund_model.dart';
import '../models/chit_auction_model.dart';
import '../models/chit_loan_model.dart';

class ChitFundService {
  final Dio _dio = ApiClient.instance.client;

  // ─── Chit Funds ──────────────────────────────────────────────────────────────

  Future<List<ChitFund>> listChitFunds({String? status}) async {
    try {
      final response = await _dio.get(
        ApiConstants.chitFunds,
        queryParameters: {if (status != null) 'status': status},
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitFund.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitFund> getChitFund(String id) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundById(id));
      return ChitFund.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitFund> createChitFund({
    required String name,
    String? description,
    required int memberCount,
    required num monthlyContribution,
    required num startingBid,
    required DateTime startDate,
    num interestRate = 3,
    int paymentDueDay = 1,
    String? loanPeriodRule,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.chitFunds, data: {
        'name': name,
        if (description != null) 'description': description,
        'memberCount': memberCount,
        'monthlyContribution': monthlyContribution,
        'startingBid': startingBid,
        'startDate': startDate.toIso8601String(),
        'interestRate': interestRate,
        'paymentDueDay': paymentDueDay,
        if (loanPeriodRule != null) 'loanPeriodRule': loanPeriodRule,
      });
      return ChitFund.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitFund> updateChitFund(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.chitFundById(id), data: data);
      return ChitFund.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Members ──────────────────────────────────────────────────────────────────

  Future<List<ChitMember>> listMembers(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundMembers(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitMember.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addMember(String chitId, String customerId) async {
    try {
      await _dio.post(ApiConstants.chitFundMembers(chitId), data: {'customerId': customerId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> removeMember(String chitId, String memberId) async {
    try {
      await _dio.delete(ApiConstants.chitFundMember(chitId, memberId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Months ───────────────────────────────────────────────────────────────────

  Future<List<ChitMonth>> listMonths(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundMonths(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitMonth.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitMonth> createMonth(String chitId, DateTime periodStart) async {
    try {
      final response = await _dio.post(
        ApiConstants.chitFundMonths(chitId),
        data: {'periodStart': periodStart.toIso8601String()},
      );
      return ChitMonth.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> closeMonth(String chitId, String monthId) async {
    try {
      await _dio.post(ApiConstants.chitFundMonthClose(chitId, monthId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMonthSummary(String chitId, String monthId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundMonthSummary(chitId, monthId));
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Auctions ─────────────────────────────────────────────────────────────────

  Future<List<ChitAuction>> listAuctions(String chitId, {String? monthId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.chitFundAuctions(chitId),
        queryParameters: {if (monthId != null) 'monthId': monthId},
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitAuction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitAuction>> createAuctions(
      String chitId, String monthId, List<Map<String, dynamic>> auctionList) async {
    try {
      final response = await _dio.post(
        ApiConstants.chitFundAuctions(chitId),
        data: {'monthId': monthId, 'auctions': auctionList},
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitAuction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markPayoutPaid(String auctionId, {String? paymentReference}) async {
    try {
      await _dio.post(
        ApiConstants.chitAuctionPayoutPaid(auctionId),
        data: {if (paymentReference != null) 'paymentReference': paymentReference},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Member Payments ──────────────────────────────────────────────────────────

  Future<List<ChitMemberPayment>> listPayments(String chitId,
      {String? monthId, String? memberId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.chitFundPayments(chitId),
        queryParameters: {
          if (monthId != null) 'monthId': monthId,
          if (memberId != null) 'memberId': memberId,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitMemberPayment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitMemberPayment> recordPayment({
    required String chitId,
    required String memberId,
    required String monthId,
    required num amountPaid,
    required String paymentMethod,
    String? paymentReference,
    DateTime? paidDate,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.chitFundPayments(chitId), data: {
        'memberId': memberId,
        'monthId': monthId,
        'amountPaid': amountPaid,
        'paymentMethod': paymentMethod,
        if (paymentReference != null) 'paymentReference': paymentReference,
        if (paidDate != null) 'paidDate': paidDate.toIso8601String(),
      });
      return ChitMemberPayment.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMonthPaymentStatus(String chitId, String monthId) async {
    try {
      final response = await _dio.get(
        ApiConstants.chitFundPaymentStatus(chitId),
        queryParameters: {'monthId': monthId},
      );
      final list = response.data['data'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Loans ─────────────────────────────────────────────────────────────────────

  Future<List<ChitLoan>> listLoans(String chitId, {String? status}) async {
    try {
      final response = await _dio.get(
        ApiConstants.chitFundLoans(chitId),
        queryParameters: {if (status != null) 'status': status},
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitLoan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitLoan> getLoan(String loanId) async {
    try {
      final response = await _dio.get(ApiConstants.chitLoan(loanId));
      return ChitLoan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitLoan> createLoan({
    required String chitId,
    required String memberId,
    required num principalAmount,
    required DateTime loanDate,
    required DateTime dueDate,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.chitFundLoans(chitId), data: {
        'memberId': memberId,
        'principalAmount': principalAmount,
        'loanDate': loanDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
      });
      return ChitLoan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitLoan> repayLoan({
    required String loanId,
    required num principalAmount,
    required num interestAmount,
    String? paymentReference,
    String? paymentMethod,
    DateTime? transactionDate,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.chitLoanRepay(loanId), data: {
        'principalAmount': principalAmount,
        'interestAmount': interestAmount,
        if (paymentReference != null) 'paymentReference': paymentReference,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (transactionDate != null) 'transactionDate': transactionDate.toIso8601String(),
      });
      return ChitLoan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── Fund & Reports ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFundSummary(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundFund(chitId));
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitFundLedger>> getLedger(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundLedger(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitFundLedger.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSummaryReport(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundReportSummary(chitId));
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getMonthlyReport(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundReportMonthly(chitId));
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getAuctionReport(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundReportAuctions(chitId));
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getLoanReport(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundReportLoans(chitId));
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getMemberReport(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.chitFundReportMembers(chitId));
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── My Chits (Customer) ──────────────────────────────────────────────────────

  Future<List<ChitMember>> listMyChits() async {
    try {
      final response = await _dio.get(ApiConstants.myChits);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitMember.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitMember> getMyChit(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitById(chitId));
      return ChitMember.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitMemberPayment>> getMyPayments(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitPayments(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitMemberPayment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitAuction>> getMyAuctions(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitAuctions(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitAuction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitLoan>> getMyLoans(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitLoans(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitLoan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChitLoan> getMyLoanDetail(String chitId, String loanId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitLoanDetail(chitId, loanId));
      return ChitLoan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChitFundLedger>> getMyLedger(String chitId) async {
    try {
      final response = await _dio.get(ApiConstants.myChitLedger(chitId));
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ChitFundLedger.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
