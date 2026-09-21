import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/document_model.dart';

class DocumentService {
  final Dio _dio = ApiClient.instance.client;

  Future<List<CustomerDocument>> listByCustomer(String customerId) async {
    try {
      final response = await _dio.get('/documents/customer/$customerId');
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => CustomerDocument.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Uploads a KYC document for [customerId]. [type] must be one of
  /// AADHAAR, PAN, AGREEMENT, OTHER (matches backend DocumentType enum).
  Future<void> uploadDocument({
    required String customerId,
    required String type,
    required String filePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
      });
      await _dio.post(
        '${ApiConstants.customers}/$customerId/documents',
        data: formData,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Downloads a document to [savePath] (caller supplies a temp/local path).
  Future<void> downloadDocument(String documentId, String savePath) async {
    try {
      await _dio.download('/documents/$documentId/download', savePath);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _dio.delete('/documents/$documentId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
