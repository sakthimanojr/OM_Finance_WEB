class AuditLogEntry {
  AuditLogEntry({
    required this.id,
    required this.adminId,
    this.adminPhone,
    this.adminRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  final String id;
  final String adminId;
  final String? adminPhone;
  final String? adminRole;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    return AuditLogEntry(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      adminPhone: admin?['phone'] as String?,
      adminRole: admin?['role'] as String?,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
