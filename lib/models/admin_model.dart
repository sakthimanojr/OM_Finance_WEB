class AdminUser {
  AdminUser({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String phone;
  final String? email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        role: json['role'] as String,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}

class SystemConfig {
  SystemConfig({this.upiId, this.smsProvider, this.smsApiKey, this.smtpConfig, this.updatedAt});

  final String? upiId;
  final String? smsProvider;
  final String? smsApiKey;
  final Map<String, dynamic>? smtpConfig;
  final DateTime? updatedAt;

  factory SystemConfig.fromJson(Map<String, dynamic> json) => SystemConfig(
        upiId: json['upiId'] as String?,
        smsProvider: json['smsProvider'] as String?,
        smsApiKey: json['smsApiKey'] as String?,
        smtpConfig: json['smtpConfig'] as Map<String, dynamic>?,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      );
}
