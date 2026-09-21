import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/loan_model.dart';

class LoanService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<Loan>> listLoans({String? customerId, String? status, String? type, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.loans,
        queryParameters: {
          if (customerId != null) 'customerId': customerId,
          if (status != null) 'status': status,
          if (type != null) 'type': type,
          'page': page,
          'limit': 20,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Loan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Loan> getLoan(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.loans}/$id');
      return Loan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Loan> createLoan({
    required String customerId,
    required String loanNumber,
    required String type,
    required num principal,
    required num interestRate,
    num agreementFee = 0,
    int? termCount,
    required DateTime startDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loans,
        data: {
          'customerId': customerId,
          'loanNumber': loanNumber,
          'type': type,
          'principal': principal,
          'interestRate': interestRate,
          'agreementFee': agreementFee,
          if (termCount != null) 'termCount': termCount,
          'startDate': startDate.toIso8601String(),
        },
      );
      return Loan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> closeLoan(String id, {String? remarks}) async {
    try {
      await _dio.patch('${ApiConstants.loans}/$id/close', data: {if (remarks != null) 'remarks': remarks});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> repayPrincipal(String loanId, num amount, String paymentMethod) async {
    try {
      await _dio.post(
        '${ApiConstants.loans}/$loanId/repay-principal',
        data: {'amount': amount, 'paymentMethod': paymentMethod},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
