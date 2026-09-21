import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ReportJsonService {
  final Dio _dio = ApiClient.instance.client;

  Future<Map<String, dynamic>> monthlyCollections() async {
    final r = await _dio.get(ApiConstants.reportsMonthlyCollections);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loanPortfolio() async {
    final r = await _dio.get(ApiConstants.reportsLoanPortfolioJson);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> interestProfit() async {
    final r = await _dio.get(ApiConstants.reportsInterestProfit);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> overdueDetail() async {
    final r = await _dio.get(ApiConstants.reportsOverdueDetail);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> disbursementSummary() async {
    final r = await _dio.get(ApiConstants.reportsDisbursementSummary);
    return r.data['data'] as Map<String, dynamic>;
  }
}
