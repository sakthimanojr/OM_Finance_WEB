import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class DailyRecordService {
  final Dio _dio = ApiClient.instance.client;

  /// Fetch a daily record for a specific date (YYYY-MM-DD).
  /// Returns auto-computed + saved data combined.
  Future<Map<String, dynamic>> getRecord(String date) async {
    try {
      final r = await _dio.get(
        ApiConstants.dailyRecords,
        queryParameters: {'date': date},
      );
      return r.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Save (upsert) a daily record for a specific date.
  Future<Map<String, dynamic>> saveRecord(Map<String, dynamic> payload) async {
    try {
      final r = await _dio.post(ApiConstants.dailyRecords, data: payload);
      return r.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
