import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

/// Thin wrapper around Dio configured with:
/// - base URL + JSON headers
/// - automatic Bearer token attachment
/// - automatic access-token refresh on a single 401 retry
/// - request/response logging in debug builds
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRetry = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isRetry) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final token = await TokenStorage.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // fall through to original error
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        compact: true,
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get client => _dio;

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['data']['accessToken'] as String?;
      if (newAccessToken == null) return false;

      await TokenStorage.saveAccessToken(newAccessToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Standardized exception thrown by services when an API call fails,
/// carrying a user-friendly message extracted from the backend response.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});
  final String message;
  final int? statusCode;
  final dynamic errors;

  @override
  String toString() => message;

  static ApiException fromDioError(DioException e) {
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Check your internet and try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Could not reach the server. Check your connection.';
    }
    return ApiException(
      message,
      statusCode: e.response?.statusCode,
      errors: data is Map ? data['errors'] : null,
    );
  }
}
