class AppUser {
  AppUser({required this.id, required this.role, required this.phone, this.email, this.canEdit = false});

  final String id;
  final String role;
  final String phone;
  final String? email;
  final bool canEdit;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        canEdit: json['canEdit'] as bool? ?? (json['role'] == 'SUPER_ADMIN'),
      );

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isViewAdmin => role == 'VIEW_ADMIN';
  bool get isAdmin => isSuperAdmin || isViewAdmin;
  bool get isCustomer => role == 'CUSTOMER';

  /// True if user is Super Admin OR View Admin with edit access enabled
  bool get canPerformAdminActions => isSuperAdmin || (isViewAdmin && canEdit);
}
