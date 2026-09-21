class ClosedLoan {
  ClosedLoan({
    required this.id,
    required this.loanId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.loanType,
    this.loanNumber,
    required this.principal,
    required this.interestRate,
    required this.disbursedAmount,
    required this.totalCollected,
    required this.startDate,
    this.endDate,
    required this.closedAt,
    required this.paymentHistory,
    required this.dueSchedule,
  });

  final String id;
  final String loanId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String loanType;
  final String? loanNumber;
  final num principal;
  final num interestRate;
  final num disbursedAmount;
  final num totalCollected;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime closedAt;
  final List<Map<String, dynamic>> paymentHistory;
  final List<Map<String, dynamic>> dueSchedule;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ClosedLoan.fromJson(Map<String, dynamic> json) {
    return ClosedLoan(
      id: json['id'] as String,
      loanId: json['loanId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      loanType: json['loanType'] as String,
      loanNumber: json['loanNumber'] as String?,
      principal: _toNum(json['principal']),
      interestRate: _toNum(json['interestRate']),
      disbursedAmount: _toNum(json['disbursedAmount']),
      totalCollected: _toNum(json['totalCollected']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      closedAt: DateTime.parse(json['closedAt'] as String),
      paymentHistory: (json['paymentHistory'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      dueSchedule: (json['dueSchedule'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
