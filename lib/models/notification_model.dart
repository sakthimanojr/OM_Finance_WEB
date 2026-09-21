class AppNotification {
  AppNotification({
    required this.id,
    required this.customerId,
    required this.channel,
    required this.type,
    required this.message,
    required this.status,
    this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String channel;
  final String type;
  final String message;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        channel: json['channel'] as String,
        type: json['type'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
