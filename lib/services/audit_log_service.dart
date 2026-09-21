import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<AuditLogEntry>> listAuditLogs({String? entityType, String? action, String? paymentMethod, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.auditLogs,
        queryParameters: {
          if (entityType != null) 'entityType': entityType,
          if (action != null) 'action': action,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          'page': page,
          'limit': 30,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
