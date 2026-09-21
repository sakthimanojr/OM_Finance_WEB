class AppUser {
  AppUser({required this.id, required this.role, required this.phone, this.email});

  final String id;
  final String role;
  final String phone;
  final String? email;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
      );

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isViewAdmin => role == 'VIEW_ADMIN';
  bool get isAdmin => isSuperAdmin || isViewAdmin;
  bool get isCustomer => role == 'CUSTOMER';
}
