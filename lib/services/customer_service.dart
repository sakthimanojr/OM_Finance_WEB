import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomerService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<Customer>> listCustomers({String? search, String? status, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.customers,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status,
          'page': page,
          'limit': 200,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Customer> getMyProfile() async {
    try {
      final response = await _dio.get(ApiConstants.customerMe);
      return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Customer> getCustomer(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.customers}/$id');
      return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConstants.customers, data: payload);
      return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch('${ApiConstants.customers}/$id', data: payload);
      return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> uploadDocument(String customerId, String type, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
      });
      await _dio.post('${ApiConstants.customers}/$customerId/documents', data: formData);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
