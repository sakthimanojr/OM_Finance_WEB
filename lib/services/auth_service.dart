import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../models/user_model.dart';

class AuthResult {
  AuthResult({required this.user, required this.accessToken, required this.refreshToken});
  final AppUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthService {
  final Dio _dio = ApiClient.instance.client;

  Future<AuthResult> login(String phone, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'phone': phone, 'password': password},
      );
      return _handleAuthResponse(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post(ApiConstants.otpRequest, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResult> verifyOtp(String phone, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.otpVerify,
        data: {'phone': phone, 'otp': otp},
      );
      return _handleAuthResponse(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> forgotPassword(String phone) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword(String phone, String otp, String newPassword) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {'phone': phone, 'otp': otp, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResult> _handleAuthResponse(Map<String, dynamic> data) async {
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await TokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: user.id,
      role: user.role,
      phone: user.phone,
    );

    return AuthResult(user: user, accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }
}
