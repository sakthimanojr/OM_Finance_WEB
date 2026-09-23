import 'due_model.dart';

class Loan {
  Loan({
    required this.id,
    required this.customerId,
    this.loanNumber,
    required this.type,
    required this.principal,
    required this.interestRate,
    this.agreementFee = 0,
    required this.disbursedAmount,
    required this.totalCollection,
    required this.startDate,
    this.endDate,
    required this.status,
    this.termCount,
    this.installmentAmount,
    this.customerName,
    this.customerPhone,
    this.dues = const [],
  });

  final String id;
  final String customerId;
  final String? loanNumber;
  final String type;
  final num principal;
  final num interestRate;
  final num agreementFee;
  final num disbursedAmount;
  final num totalCollection;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final int? termCount;
  final num? installmentAmount;
  final String? customerName;
  final String? customerPhone;
  final List<Due> dues;

  /// Prisma returns Decimal columns as strings; this helper handles both.
  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());
  static num? _toNumNullable(dynamic v) => v == null ? null : _toNum(v);

  factory Loan.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return Loan(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      loanNumber: json['loanNumber'] as String?,
      type: json['type'] as String,
      principal: _toNum(json['principal']),
      interestRate: _toNum(json['interestRate']),
      agreementFee: _toNumNullable(json['agreementFee']) ?? 0,
      disbursedAmount: _toNum(json['disbursedAmount']),
      totalCollection: _toNum(json['totalCollection'] ?? 0),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      status: json['status'] as String,
      termCount: json['termCount'] as int?,
      installmentAmount: _toNumNullable(json['installmentAmount']),
      customerName: customer?['name'] as String?,
      customerPhone: customer?['phone'] as String?,
      dues: (json['dues'] as List<dynamic>? ?? [])
          .map((d) => Due.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  num get outstandingAmount {
    final pendingDues = dues.where((d) => d.status != 'PAID');
    return pendingDues.fold<num>(0, (sum, d) => sum + d.amount);
  }
}
