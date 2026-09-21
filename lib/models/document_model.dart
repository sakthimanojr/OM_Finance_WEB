class CustomerDocument {
  CustomerDocument({
    required this.id,
    required this.customerId,
    required this.type,
    required this.fileUrl,
    required this.uploadedAt,
  });

  final String id;
  final String customerId;
  final String type;
  final String fileUrl;
  final DateTime uploadedAt;

  factory CustomerDocument.fromJson(Map<String, dynamic> json) => CustomerDocument(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        type: json['type'] as String,
        fileUrl: json['fileUrl'] as String,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );

  String get displayName {
    switch (type) {
      case 'AADHAAR':
        return 'Aadhaar Card';
      case 'PAN':
        return 'PAN Card';
      case 'AGREEMENT':
        return 'Loan Agreement';
      default:
        return 'Other Document';
    }
  }
}
