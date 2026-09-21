class AppConstants {
  AppConstants._();

  static const String appName = 'Finance App';

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userPhoneKey = 'user_phone';

  // Roles (must match backend enum values)
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleViewAdmin = 'VIEW_ADMIN';
  static const String roleCustomer = 'CUSTOMER';

  // Loan types
  static const String loanWeekly = 'WEEKLY';
  static const String loanMonthly = 'MONTHLY';
  static const String loanHighValue = 'HIGH_VALUE';

  // Due status
  static const String duePending = 'PENDING';
  static const String duePaid = 'PAID';
  static const String dueMissed = 'MISSED';
}
