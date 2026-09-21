class Due {
  Due({
    required this.id,
    required this.loanId,
    required this.dueNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    this.paidAmount,
    this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.loanType,
  });

  final String id;
  final String loanId;
  final int dueNumber;
  final DateTime dueDate;
  final num amount;
  final String status;
  final DateTime? paidDate;
  final num? paidAmount;
  final String? paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? loanType;

  static num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());

  factory Due.fromJson(Map<String, dynamic> json) {
    final loan = json['loan'] as Map<String, dynamic>?;
    final customer = loan?['customer'] as Map<String, dynamic>?;
    return Due(
      id: json['id'] as String,
      loanId: json['loanId'] as String,
      dueNumber: json['dueNumber'] as int,
      dueDate: DateTime.parse(json['dueDate'] as String),
      amount: _toNum(json['amount']),
      status: json['status'] as String,
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate']) : null,
      paidAmount: json['paidAmount'] != null ? _toNum(json['paidAmount']) : null,
      paymentMethod: json['paymentMethod'] as String?,
      customerName: customer?['name'] as String?,
      customerPhone: customer?['phone'] as String?,
      loanType: loan?['type'] as String?,
    );
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => status != 'PAID' && dueDate.isBefore(DateTime.now());
}
