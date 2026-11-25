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

  static num _toNum(dynamic v) => v is num ? v : (v == null ? 0 : (num.tryParse(v.toString()) ?? 0));

  factory Due.fromJson(Map<String, dynamic> json) {
    final loan = json['loan'] is Map ? Map<String, dynamic>.from(json['loan'] as Map) : null;
    final customer = loan?['customer'] is Map ? Map<String, dynamic>.from(loan!['customer'] as Map) : null;
    return Due(
      id: json['id']?.toString() ?? '',
      loanId: json['loanId']?.toString() ?? '',
      dueNumber: json['dueNumber'] is int
          ? json['dueNumber'] as int
          : (int.tryParse(json['dueNumber']?.toString() ?? '0') ?? 0),
      dueDate: json['dueDate'] != null
          ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      amount: _toNum(json['amount']),
      status: json['status']?.toString() ?? 'PENDING',
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate'].toString()) : null,
      paidAmount: json['paidAmount'] != null ? _toNum(json['paidAmount']) : null,
      paymentMethod: json['paymentMethod']?.toString(),
      customerName: customer?['name']?.toString() ?? json['customerName']?.toString(),
      customerPhone: customer?['phone']?.toString() ?? json['customerPhone']?.toString(),
      loanType: loan?['type']?.toString() ?? json['loanType']?.toString(),
    );
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => status != 'PAID' && dueDate.isBefore(DateTime.now());
}
