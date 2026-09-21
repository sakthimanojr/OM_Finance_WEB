import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final Dio _dio = ApiClient.instance.client;

  Future<AdminSummary> getAdminSummary() async {
    try {
      final response = await _dio.get(ApiConstants.dashboardAdminSummary);
      return AdminSummary.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSummary> getCustomerSummary({String? customerId}) async {
    try {
      final path = customerId != null
          ? '${ApiConstants.dashboardCustomerSummary}/$customerId'
          : ApiConstants.dashboardCustomerSummary;
      final response = await _dio.get(path);
      return CustomerSummary.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
