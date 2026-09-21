import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/admin_model.dart';

class AdminManagementService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<AdminUser>> listAdmins() async {
    try {
      final response = await _dio.get(ApiConstants.adminViewAdmins);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AdminUser> createViewAdmin({required String phone, String? email, required String password}) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminViewAdmins,
        data: {'phone': phone, if (email != null && email.isNotEmpty) 'email': email, 'password': password},
      );
      return AdminUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> setAdminActive(String id, bool isActive) async {
    try {
      await _dio.patch('${ApiConstants.adminViewAdmins}/$id/status', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SystemConfig> getConfig() async {
    try {
      final response = await _dio.get(ApiConstants.adminConfig);
      return SystemConfig.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SystemConfig> updateConfig({
    String? upiId,
    String? smsProvider,
    String? smsApiKey,
    Map<String, dynamic>? smtpConfig,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.adminConfig,
        data: {
          if (upiId != null) 'upiId': upiId,
          if (smsProvider != null) 'smsProvider': smsProvider,
          if (smsApiKey != null && smsApiKey.isNotEmpty) 'smsApiKey': smsApiKey,
          if (smtpConfig != null) 'smtpConfig': smtpConfig,
        },
      );
      return SystemConfig.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
