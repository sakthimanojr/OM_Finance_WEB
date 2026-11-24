import 'package:flutter/material.dart';
import '../core/utils/profile_color.dart';

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
    this.loanNumber,
    this.activeLoanNumber,
    this.loanStatus,
    this.loans,
    this.loanStartDate,
    this.loanCreatedAt,
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
  final String? loanNumber;
  final String? activeLoanNumber;
  final String? loanStatus;
  final List<dynamic>? loans;
  final DateTime? loanStartDate;
  final DateTime? loanCreatedAt;

  /// Effective date when the customer's loan was created / started.
  DateTime? get loanCreationDate {
    if (loanStartDate != null) return loanStartDate;
    if (loanCreatedAt != null) return loanCreatedAt;
    if (loans != null && loans!.isNotEmpty) {
      final first = loans!.first;
      if (first is Map) {
        if (first['startDate'] != null) {
          final parsed = DateTime.tryParse(first['startDate'].toString());
          if (parsed != null) return parsed;
        }
        if (first['createdAt'] != null) {
          final parsed = DateTime.tryParse(first['createdAt'].toString());
          if (parsed != null) return parsed;
        }
      }
    }
    return createdAt;
  }

  /// Day-of-the-week profile color based on when the loan was created:
  /// Mon: Pink, Tue: Green, Wed: Brown, Thu: Orange, Fri: Sky Blue, Sat: Red, Sun: Black
  Color get dayColor => ProfileDayColor.forDateTime(loanCreationDate);
  String get dayName => ProfileDayColor.dayName(loanCreationDate);
  String get shortDay => ProfileDayColor.shortDay(loanCreationDate);

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
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        loanNumber: json['loanNumber'] as String?,
        activeLoanNumber: json['activeLoanNumber'] as String?,
        loanStatus: json['loanStatus'] as String?,
        loans: json['loans'] as List<dynamic>?,
        loanStartDate: json['loanStartDate'] != null ? DateTime.tryParse(json['loanStartDate'].toString()) : null,
        loanCreatedAt: json['loanCreatedAt'] != null ? DateTime.tryParse(json['loanCreatedAt'].toString()) : null,
      );
}
