import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
    required String phone,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
    await _storage.write(key: AppConstants.userIdKey, value: userId);
    await _storage.write(key: AppConstants.userRoleKey, value: role);
    await _storage.write(key: AppConstants.userPhoneKey, value: phone);
  }

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() => _storage.read(key: AppConstants.accessTokenKey);
  static Future<String?> getRefreshToken() => _storage.read(key: AppConstants.refreshTokenKey);
  static Future<String?> getRole() => _storage.read(key: AppConstants.userRoleKey);
  static Future<String?> getUserId() => _storage.read(key: AppConstants.userIdKey);
  static Future<String?> getPhone() => _storage.read(key: AppConstants.userPhoneKey);

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
