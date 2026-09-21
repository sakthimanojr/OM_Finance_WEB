class ChitFund {
  ChitFund({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.monthlyContribution,
    required this.regularAuctionAmount,
    required this.startingBid,
    required this.interestRate,
    required this.startDate,
    required this.paymentDueDay,
    required this.currentMonth,
    required this.completedAuctionCount,
    required this.requiredWinnerCount,
    required this.status,
    this.membersList,
    this.count,
  });

  final String id;
  final String name;
  final String? description;
  final int memberCount;
  final num monthlyContribution;
  final num regularAuctionAmount;
  final num startingBid;
  final num interestRate;
  final DateTime startDate;
  final int paymentDueDay;
  final int currentMonth;
  final int completedAuctionCount;
  final int requiredWinnerCount;
  final String status;
  final List<ChitMember>? membersList;
  final Map<String, int>? count;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitFund.fromJson(Map<String, dynamic> json) {
    List<ChitMember>? members;
    if (json['members'] is List) {
      members = (json['members'] as List)
          .map((e) => ChitMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ChitFund(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: (json['memberCount'] as num).toInt(),
      monthlyContribution: _n(json['monthlyContribution']),
      regularAuctionAmount: _n(json['regularAuctionAmount']),
      startingBid: _n(json['startingBid']),
      interestRate: _n(json['interestRate'] ?? 3),
      startDate: DateTime.parse(json['startDate'] as String),
      paymentDueDay: (json['paymentDueDay'] as num? ?? 1).toInt(),
      currentMonth: (json['currentMonth'] as num? ?? 0).toInt(),
      completedAuctionCount: (json['completedAuctionCount'] as num? ?? 0).toInt(),
      requiredWinnerCount: (json['requiredWinnerCount'] as num? ?? 0).toInt(),
      status: json['status'] as String,
      membersList: members,
      count: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()))
          : null,
    );
  }

  int get remainingWinners => requiredWinnerCount - completedAuctionCount;
  num get totalChitValue => memberCount * monthlyContribution;
}

class ChitMember {
  ChitMember({
    required this.id,
    required this.chitId,
    required this.userId,
    required this.customerId,
    required this.monthlyContribution,
    required this.auctionEligible,
    required this.hasWonAuction,
    this.wonAuctionId,
    this.wonAuctionNumber,
    required this.status,
    required this.joinedAt,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.chitCount,
    this.chit,
    this.membershipLabel,
  });

  final String id;
  final String chitId;
  final String userId;
  final String customerId;
  final num monthlyContribution;
  final bool auctionEligible;
  final bool hasWonAuction;
  final String? wonAuctionId;
  final int? wonAuctionNumber;
  final String status;
  final DateTime joinedAt;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? chitCount;
  final ChitFund? chit;
  final String? membershipLabel;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitMember.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final chitJson = json['chit'] as Map<String, dynamic>?;
    return ChitMember(
      id: json['id'] as String,
      chitId: json['chitId'] as String,
      userId: json['userId'] as String,
      customerId: json['customerId'] as String,
      monthlyContribution: _n(json['monthlyContribution'] ?? 0),
      auctionEligible: json['auctionEligible'] as bool? ?? true,
      hasWonAuction: json['hasWonAuction'] as bool? ?? false,
      wonAuctionId: json['wonAuctionId'] as String?,
      wonAuctionNumber: (json['wonAuctionNumber'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'ACTIVE',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      customerName: customer?['name'] as String?,
      customerPhone: customer?['phone'] as String?,
      customerEmail: customer?['email'] as String?,
      chitCount: (json['chitCount'] as num?)?.toInt(),
      chit: chitJson != null ? ChitFund.fromJson(chitJson) : null,
      membershipLabel: json['membershipLabel'] as String?,
    );
  }

  String get displayName {
    final name = customerName ?? 'Unknown';
    if (chitCount != null && chitCount! > 1) return '$name ($chitCount)';
    return name;
  }
}

class ChitMonth {
  ChitMonth({
    required this.id,
    required this.chitId,
    required this.monthNumber,
    required this.periodStart,
    this.periodEnd,
    required this.amountDue,
    required this.amountCollected,
    required this.status,
    this.auctionCount,
  });

  final String id;
  final String chitId;
  final int monthNumber;
  final DateTime periodStart;
  final DateTime? periodEnd;
  final num amountDue;
  final num amountCollected;
  final String status;
  final int? auctionCount;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitMonth.fromJson(Map<String, dynamic> json) {
    return ChitMonth(
      id: json['id'] as String,
      chitId: json['chitId'] as String,
      monthNumber: (json['monthNumber'] as num).toInt(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: json['periodEnd'] != null ? DateTime.parse(json['periodEnd'] as String) : null,
      amountDue: _n(json['amountDue']),
      amountCollected: _n(json['amountCollected'] ?? 0),
      status: json['status'] as String,
      auctionCount: (json['_count'] as Map<String, dynamic>?)?['auctions'] as int?,
    );
  }
}
