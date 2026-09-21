class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.fatherName,
    this.address,
    this.aadhaarLast4,
    this.pan,
    this.occupation,
    this.monthlyIncome,
    this.guarantorName,
    this.guarantorPhone,
    this.emergencyContact,
    this.photoUrl,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? fatherName;
  final String? address;
  final String? aadhaarLast4;
  final String? pan;
  final String? occupation;
  final num? monthlyIncome;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? emergencyContact;
  final String? photoUrl;
  final String status;
  final DateTime? createdAt;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        fatherName: json['fatherName'] as String?,
        address: json['address'] as String?,
        aadhaarLast4: json['aadhaarLast4'] as String?,
        pan: json['pan'] as String?,
        occupation: json['occupation'] as String?,
        monthlyIncome: json['monthlyIncome'] != null
            ? (json['monthlyIncome'] is num ? json['monthlyIncome'] as num : num.parse(json['monthlyIncome'].toString()))
            : null,
        guarantorName: json['guarantorName'] as String?,
        guarantorPhone: json['guarantorPhone'] as String?,
        emergencyContact: json['emergencyContact'] as String?,
        photoUrl: json['photoUrl'] as String?,
        status: json['status'] as String? ?? 'ACTIVE',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}
