class ChitAuction {
  ChitAuction({
    required this.id,
    required this.chitId,
    required this.monthId,
    required this.auctionNumber,
    required this.auctionType,
    required this.auctionDate,
    required this.auctionAmount,
    required this.startingBid,
    this.winningBid,
    this.winnerId,
    this.winnerPayout,
    required this.status,
    this.winnerName,
    this.winnerPhone,
    this.monthNumber,
    this.payoutStatus,
    this.myWin,
  });

  final String id;
  final String chitId;
  final String monthId;
  final int auctionNumber;
  final String auctionType;
  final DateTime auctionDate;
  final num auctionAmount;
  final num startingBid;
  final num? winningBid;
  final String? winnerId;
  final num? winnerPayout;
  final String status;
  final String? winnerName;
  final String? winnerPhone;
  final int? monthNumber;
  final String? payoutStatus;
  final bool? myWin;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());
  static num? _nn(dynamic v) => v == null ? null : _n(v);

  factory ChitAuction.fromJson(Map<String, dynamic> json) {
    final winner = json['winner'] as Map<String, dynamic>?;
    final winnerCustomer = winner?['customer'] as Map<String, dynamic>?;
    final month = json['month'] as Map<String, dynamic>?;
    return ChitAuction(
      id: json['id'] as String,
      chitId: json['chitId'] as String? ?? '',
      monthId: json['monthId'] as String? ?? '',
      auctionNumber: (json['auctionNumber'] as num).toInt(),
      auctionType: json['auctionType'] as String,
      auctionDate: DateTime.parse(json['auctionDate'] as String),
      auctionAmount: _n(json['auctionAmount']),
      startingBid: _n(json['startingBid'] ?? 0),
      winningBid: _nn(json['winningBid']),
      winnerId: json['winnerId'] as String?,
      winnerPayout: _nn(json['winnerPayout']),
      status: json['status'] as String,
      winnerName: winnerCustomer?['name'] as String? ?? json['winnerName'] as String?,
      winnerPhone: winnerCustomer?['phone'] as String?,
      monthNumber: (month?['monthNumber'] as num?)?.toInt(),
      payoutStatus: json['payout'] != null
          ? (json['payout'] as Map<String, dynamic>)['status'] as String?
          : null,
      myWin: json['myWin'] as bool?,
    );
  }
}

class ChitFundLedger {
  ChitFundLedger({
    required this.id,
    required this.chitId,
    required this.transactionType,
    required this.amount,
    required this.direction,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.auctionNumber,
    this.auctionType,
    this.loanMemberName,
  });

  final String id;
  final String chitId;
  final String transactionType;
  final num amount;
  final String direction;
  final num balanceAfter;
  final String description;
  final DateTime createdAt;
  final int? auctionNumber;
  final String? auctionType;
  final String? loanMemberName;

  static num _n(dynamic v) => v is num ? v : num.parse(v.toString());

  factory ChitFundLedger.fromJson(Map<String, dynamic> json) {
    final auction = json['auction'] as Map<String, dynamic>?;
    final loan = json['loan'] as Map<String, dynamic>?;
    final loanMember = loan?['member'] as Map<String, dynamic>?;
    final loanCustomer = loanMember?['customer'] as Map<String, dynamic>?;
    return ChitFundLedger(
      id: json['id'] as String,
      chitId: json['chitId'] as String,
      transactionType: json['transactionType'] as String,
      amount: _n(json['amount']),
      direction: json['direction'] as String,
      balanceAfter: _n(json['balanceAfter']),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      auctionNumber: (auction?['auctionNumber'] as num?)?.toInt(),
      auctionType: auction?['auctionType'] as String?,
      loanMemberName: loanCustomer?['name'] as String?,
    );
  }
}
