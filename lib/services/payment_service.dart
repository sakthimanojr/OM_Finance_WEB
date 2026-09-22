import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/payment_model.dart';

class InitiatePaymentResult {
  InitiatePaymentResult({required this.payment, this.upiIntent, this.razorpayOrder});
  final Payment payment;
  final UpiIntent? upiIntent;
  final RazorpayOrder? razorpayOrder;
}

class PaymentService {
  final Dio _dio = ApiClient.instance.client;

  Future<InitiatePaymentResult> initiatePayment({
    required String dueId,
    required String method,
    required num amount,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.paymentsInitiate,
        data: {'dueId': dueId, 'method': method, 'amount': amount},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final payment = Payment.fromJson(data['payment'] as Map<String, dynamic>);
      final upiPayload = data['upiPayload'] as Map<String, dynamic>?;
      final razorpayOrderJson = data['razorpayOrder'] as Map<String, dynamic>?;
      return InitiatePaymentResult(
        payment: payment,
        upiIntent: upiPayload != null ? UpiIntent.fromJson(upiPayload) : null,
        razorpayOrder: razorpayOrderJson != null ? RazorpayOrder.fromJson(razorpayOrderJson) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Payment> confirmPayment(String paymentId, {String? upiRefNumber, DateTime? paidAt}) async {
    try {
      final response = await _dio.post(
        ApiConstants.paymentsConfirm,
        data: {
          'paymentId': paymentId,
          if (upiRefNumber != null) 'upiRefNumber': upiRefNumber,
          // Send ISO-8601 string so the backend can backdate paidAt/paidDate
          if (paidAt != null) 'paidAt': paidAt.toIso8601String(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Payment.fromJson(data['payment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Payment>> listPayments({String? customerId, String? loanId, String? month, int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.payments,
        queryParameters: {
          if (customerId != null) 'customerId': customerId,
          if (loanId != null) 'loanId': loanId,
          if (month != null) 'month': month,
          'page': page,
          'limit': 20,
        },
      );
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
