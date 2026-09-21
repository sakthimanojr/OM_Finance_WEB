class Payment {
  Payment({
    required this.id,
    required this.dueId,
    required this.loanId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    this.upiRefNumber,
    this.paidAt,
    this.receiptId,
    this.receiptNumber,
    this.billNumber,
    this.customerName,
    this.createdAt,
  });

  final String id;
  final String dueId;
  final String loanId;
  final String customerId;
  final num amount;
  final String method;
  final String status;
  final String? upiRefNumber;
  final DateTime? paidAt;
  final String? receiptId;
  final String? receiptNumber;
  final int? billNumber;
  final String? customerName;
  final DateTime? createdAt;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());

  factory Payment.fromJson(Map<String, dynamic> json) {
    final receipt = json['receipt'] as Map<String, dynamic>?;
    return Payment(
      id: json['id'] as String,
      dueId: json['dueId'] as String,
      loanId: json['loanId'] as String,
      customerId: json['customerId'] as String,
      amount: _toNum(json['amount']),
      method: json['method'] as String,
      status: json['status'] as String,
      upiRefNumber: json['upiRefNumber'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      receiptId: receipt?['id'] as String?,
      receiptNumber: receipt?['receiptNumber'] as String?,
      billNumber: receipt?['billNumber'] as int?,
      customerName: json['customer']?['name'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class UpiIntent {
  UpiIntent({required this.upiUrl, required this.qrCodeDataUrl});
  final String upiUrl;
  final String qrCodeDataUrl;

  factory UpiIntent.fromJson(Map<String, dynamic> json) => UpiIntent(
        upiUrl: json['upiUrl'] as String,
        qrCodeDataUrl: json['qrCodeDataUrl'] as String,
      );
}

/// Present only when the backend has Razorpay configured (see
/// backend/src/modules/payment/razorpay.adapter.js). When absent, the
/// frontend falls back to the static [UpiIntent] QR-code flow instead.
class RazorpayOrder {
  RazorpayOrder({required this.orderId, required this.amount, required this.currency, required this.keyId});
  final String orderId;
  final num amount;
  final String currency;
  final String keyId;

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) => RazorpayOrder(
        orderId: json['orderId'] as String,
        amount: json['amount'] is num ? json['amount'] as num : num.parse(json['amount'].toString()),
        currency: json['currency'] as String,
        keyId: json['keyId'] as String,
      );
}
