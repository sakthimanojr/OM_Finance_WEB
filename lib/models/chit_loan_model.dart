class ChitLoan {
  ChitLoan({
    required this.id,
    required this.chitId,
    required this.memberId,
    required this.principalAmount,
    required this.interestRate,
    required this.interestAmount,
    required this.totalRepayment,
    required this.amountPaid,
    required this.remainingAmount,
    required this.loanDate,
    required this.dueDate,
    required this.status,
    this.memberName,
    this.memberPhone,
    this.customerId,
    this.transactions,
  });

  final String id;
  final String chitId;
  final String memberId;
  final num principalAmount;
  final num interestRate;
  final num interestAmount;
  final num totalRepayment;
  final num amountPaid;
  final num remainingAmount;
  final DateTime loanDate;
  final DateTime dueDate;
  final String status;
  final String? memberName;
  final String? memberPhone;
  final String? customerId;
  final List<ChitLoanTransaction>? transactions;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitLoan.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>?;
    final customer = member?['customer'] as Map<String, dynamic>?;
    List<ChitLoanTransaction>? txns;
    if (json['transactions'] is List) {
      txns = (json['transactions'] as List)
          .map((e) => ChitLoanTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ChitLoan(
      id: json['id'] as String,
      chitId: json['chitId'] as String,
      memberId: json['memberId'] as String,
      principalAmount: _n(json['principalAmount']),
      interestRate: _n(json['interestRate'] ?? 3),
      interestAmount: _n(json['interestAmount']),
      totalRepayment: _n(json['totalRepayment']),
      amountPaid: _n(json['amountPaid'] ?? 0),
      remainingAmount: _n(json['remainingAmount']),
      loanDate: DateTime.parse(json['loanDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String,
      memberName: customer?['name'] as String?,
      memberPhone: customer?['phone'] as String?,
      customerId: customer?['id'] as String?,
      transactions: txns,
    );
  }

  String get loanRef => 'LN-${id.substring(id.length - 6).toUpperCase()}';
}

class ChitLoanTransaction {
  ChitLoanTransaction({
    required this.id,
    required this.loanId,
    required this.transactionType,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    this.paymentReference,
    required this.transactionDate,
  });

  final String id;
  final String loanId;
  final String transactionType;
  final num principalAmount;
  final num interestAmount;
  final num totalAmount;
  final String? paymentReference;
  final DateTime transactionDate;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitLoanTransaction.fromJson(Map<String, dynamic> json) {
    return ChitLoanTransaction(
      id: json['id'] as String,
      loanId: json['loanId'] as String,
      transactionType: json['transactionType'] as String,
      principalAmount: _n(json['principalAmount'] ?? 0),
      interestAmount: _n(json['interestAmount'] ?? 0),
      totalAmount: _n(json['totalAmount'] ?? 0),
      paymentReference: json['paymentReference'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
    );
  }
}

class ChitMemberPayment {
  ChitMemberPayment({
    required this.id,
    required this.chitId,
    required this.memberId,
    required this.monthId,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paymentReference,
    this.paymentMethod,
    this.memberName,
    this.memberPhone,
    this.monthNumber,
  });

  final String id;
  final String chitId;
  final String memberId;
  final String monthId;
  final num amountDue;
  final num amountPaid;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final String? paymentReference;
  final String? paymentMethod;
  final String? memberName;
  final String? memberPhone;
  final int? monthNumber;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitMemberPayment.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>?;
    final customer = member?['customer'] as Map<String, dynamic>?;
    final month = json['month'] as Map<String, dynamic>?;
    return ChitMemberPayment(
      id: json['id'] as String,
      chitId: json['chitId'] as String,
      memberId: json['memberId'] as String,
      monthId: json['monthId'] as String,
      amountDue: _n(json['amountDue']),
      amountPaid: _n(json['amountPaid'] ?? 0),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      status: json['status'] as String,
      paymentReference: json['paymentReference'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      memberName: customer?['name'] as String?,
      memberPhone: customer?['phone'] as String?,
      monthNumber: (month?['monthNumber'] as num?)?.toInt(),
    );
  }
}
