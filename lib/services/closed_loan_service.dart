import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/closed_loan_model.dart';

class ClosedLoanService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<ClosedLoan>> listClosedLoans({int page = 1, String? customerName}) async {
    try {
      final response = await _dio.get(
        ApiConstants.closedLoans,
        queryParameters: {
          'page': page,
          'limit': 20,
          if (customerName != null) 'customerName': customerName,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => ClosedLoan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ClosedLoan> getClosedLoan(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.closedLoans}/$id');
      return ClosedLoan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
