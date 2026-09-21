import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationHistoryService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<AppNotification>> listForCustomer(String customerId) async {
    try {
      final response = await _dio.get('/notifications/customer/$customerId');
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> sendManual({required String customerId, required String message, String channel = 'PUSH'}) async {
    try {
      await _dio.post('/notifications/send-manual', data: {
        'customerId': customerId,
        'message': message,
        'channel': channel,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
