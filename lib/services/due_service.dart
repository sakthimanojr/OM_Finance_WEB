import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/due_model.dart';

class DueService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<Due>> listDues({String? loanId, String? customerId, String? status, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.dues,
        queryParameters: {
          if (loanId != null) 'loanId': loanId,
          if (customerId != null) 'customerId': customerId,
          if (status != null) 'status': status,
          'page': page,
          'limit': 20,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Due.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Due>> getUpcoming({int days = 7}) async {
    try {
      final response = await _dio.get(ApiConstants.duesUpcoming, queryParameters: {'days': days});
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Due.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Due>> getOverdue() async {
    try {
      final response = await _dio.get(ApiConstants.duesOverdue);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Due.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Due>> getTodaysDues() async {
    try {
      final response = await _dio.get(ApiConstants.duesToday);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Due.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDuesByCustomer() async {
    try {
      final response = await _dio.get(ApiConstants.duesByCustomer);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
