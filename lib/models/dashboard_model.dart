class AdminSummary {
  AdminSummary({
    required this.totalCustomers,
    required this.activeLoans,
    required this.overdueLoans,
    required this.totalDisbursed,
    required this.totalCollected,
    required this.collectedThisMonth,
    required this.pendingDuesCount,
    required this.overdueDuesCount,
  });

  final int totalCustomers;
  final int activeLoans;
  final int overdueLoans;
  final num totalDisbursed;
  final num totalCollected;
  final num collectedThisMonth;
  final int pendingDuesCount;
  final int overdueDuesCount;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());

  factory AdminSummary.fromJson(Map<String, dynamic> json) => AdminSummary(
        totalCustomers: json['totalCustomers'] as int? ?? 0,
        activeLoans: json['activeLoans'] as int? ?? 0,
        overdueLoans: json['overdueLoans'] as int? ?? 0,
        totalDisbursed: _toNum(json['totalDisbursed'] ?? 0),
        totalCollected: _toNum(json['totalCollected'] ?? 0),
        collectedThisMonth: _toNum(json['collectedThisMonth'] ?? 0),
        pendingDuesCount: json['pendingDuesCount'] as int? ?? 0,
        overdueDuesCount: json['overdueDuesCount'] as int? ?? 0,
      );
}

class CustomerSummary {
  CustomerSummary({
    required this.totalLoans,
    required this.activeLoans,
    required this.totalOutstanding,
    this.totalPrincipalBorrowed = 0,
    this.totalPrincipalPaid = 0,
    this.totalInterestPaid = 0,
    this.totalAmountRepaid = 0,
    this.loanHistory = const [],
    this.nextDueAmount,
    this.nextDueDate,
  });

  final int totalLoans;
  final int activeLoans;
  final num totalOutstanding;
  final num totalPrincipalBorrowed;
  final num totalPrincipalPaid;
  final num totalInterestPaid;
  final num totalAmountRepaid;
  final List<LoanHistoryItem> loanHistory;
  final num? nextDueAmount;
  final DateTime? nextDueDate;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    final nextDue = json['nextDue'] as Map<String, dynamic>?;
    final historyList = json['loanHistory'] as List<dynamic>? ?? [];
    return CustomerSummary(
      totalLoans: json['totalLoans'] as int? ?? 0,
      activeLoans: json['activeLoans'] as int? ?? 0,
      totalOutstanding: _toNum(json['totalOutstanding'] ?? 0),
      totalPrincipalBorrowed: _toNum(json['totalPrincipalBorrowed'] ?? 0),
      totalPrincipalPaid: _toNum(json['totalPrincipalPaid'] ?? 0),
      totalInterestPaid: _toNum(json['totalInterestPaid'] ?? 0),
      totalAmountRepaid: _toNum(json['totalAmountRepaid'] ?? 0),
      loanHistory: historyList
          .map((e) => LoanHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextDueAmount: nextDue?['amount'] != null ? _toNum(nextDue!['amount']) : null,
      nextDueDate: nextDue?['dueDate'] != null ? DateTime.tryParse(nextDue!['dueDate']) : null,
    );
  }
}

class LoanHistoryItem {
  LoanHistoryItem({
    required this.id,
    this.loanNumber,
    required this.type,
    required this.principal,
    required this.interestRate,
    required this.disbursedAmount,
    required this.totalCollection,
    required this.status,
    required this.startDate,
    this.endDate,
    this.installmentAmount,
    this.pendingDues = 0,
    this.totalDues = 0,
  });

  final String id;
  final String? loanNumber;
  final String type;
  final num principal;
  final num interestRate;
  final num disbursedAmount;
  final num totalCollection;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final num? installmentAmount;
  final int pendingDues;
  final int totalDues;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());
  static num? _toNumNullable(dynamic v) => v == null ? null : _toNum(v);

  factory LoanHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoanHistoryItem(
      id: json['id'] as String,
      loanNumber: json['loanNumber'] as String?,
      type: json['type'] as String,
      principal: _toNum(json['principal']),
      interestRate: _toNum(json['interestRate']),
      disbursedAmount: _toNum(json['disbursedAmount']),
      totalCollection: _toNum(json['totalCollection'] ?? 0),
      status: json['status'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      installmentAmount: _toNumNullable(json['installmentAmount']),
      pendingDues: json['pendingDues'] as int? ?? 0,
      totalDues: json['totalDues'] as int? ?? 0,
    );
  }
}

