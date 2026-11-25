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
    this.disbursementMethod = 'CASH',
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
  final String disbursementMethod;
  final List<Due> dues;

  /// Prisma returns Decimal columns as strings; this helper handles both.
  static num _toNum(dynamic v) => v is num ? v : (v == null ? 0 : (num.tryParse(v.toString()) ?? 0));
  static num? _toNumNullable(dynamic v) => v == null ? null : _toNum(v);

  factory Loan.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return Loan(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      loanNumber: json['loanNumber']?.toString(),
      type: json['type']?.toString() ?? 'WEEKLY',
      principal: _toNum(json['principal']),
      interestRate: _toNum(json['interestRate']),
      agreementFee: _toNumNullable(json['agreementFee']) ?? 0,
      disbursedAmount: _toNum(json['disbursedAmount']),
      totalCollection: _toNum(json['totalCollection'] ?? 0),
      startDate: json['startDate'] != null
          ? (DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      status: json['status']?.toString() ?? 'ACTIVE',
      termCount: json['termCount'] is int
          ? json['termCount'] as int
          : (int.tryParse(json['termCount']?.toString() ?? '')),
      installmentAmount: _toNumNullable(json['installmentAmount']),
      customerName: customer?['name']?.toString() ?? json['customerName']?.toString(),
      customerPhone: customer?['phone']?.toString() ?? json['customerPhone']?.toString(),
      disbursementMethod: json['disbursementMethod']?.toString() ?? 'CASH',
      dues: (json['dues'] is List)
          ? (json['dues'] as List)
              .map((d) => d is Map ? Due.fromJson(Map<String, dynamic>.from(d)) : null)
              .whereType<Due>()
              .toList()
          : const [],
    );
  }

  num get outstandingAmount {
    final pendingDues = dues.where((d) => d.status != 'PAID');
    return pendingDues.fold<num>(0, (sum, d) => sum + d.amount);
  }
}
