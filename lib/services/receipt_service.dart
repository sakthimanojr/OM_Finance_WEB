import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class ReceiptInfo {
  ReceiptInfo({required this.id, required this.receiptNumber, this.pdfUrl, required this.generatedAt});
  final String id;
  final String receiptNumber;
  final String? pdfUrl;
  final DateTime generatedAt;

  factory ReceiptInfo.fromJson(Map<String, dynamic> json) => ReceiptInfo(
        id: json['id'] as String,
        receiptNumber: json['receiptNumber'] as String,
        pdfUrl: json['pdfUrl'] as String?,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

class ReceiptService {
  final Dio _dio = ApiClient.instance.client;

  Future<ReceiptInfo?> getByPaymentId(String paymentId) async {
    try {
      final response = await _dio.get('/receipts/payment/$paymentId');
      return ReceiptInfo.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      // No receipt yet (e.g. payment not confirmed) — treat 404 as "none".
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  /// Downloads the receipt PDF to [savePath] (caller supplies a temp/local path).
  Future<void> downloadPdf(String receiptId, String savePath) async {
    try {
      await _dio.download('/receipts/$receiptId/download', savePath);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
