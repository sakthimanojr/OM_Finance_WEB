/// Base configuration for talking to the backend.
///
/// The [baseUrl] is configured at build time via `--dart-define`:
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// For local development the default still points at the Android-emulator
/// loopback alias (`10.0.2.2`).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://om-finance-w5wg.onrender.com/api/v1',
  );

  // Auth
  static const String login = '/auth/login';
  static const String otpRequest = '/auth/otp/request';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';

  // Customers
  static const String customers = '/customers';
  static const String customerMe = '/customers/me';

  // Loans
  static const String loans = '/loans';

  // Dues
  static const String dues = '/dues';
  static const String duesUpcoming = '/dues/upcoming';
  static const String duesOverdue = '/dues/overdue';

  // Payments
  static const String paymentsInitiate = '/payments/initiate';
  static const String paymentsConfirm = '/payments/confirm';
  static const String payments = '/payments';

  // Receipts
  static const String receipts = '/receipts';

  // Notifications
  static const String notifications = '/notifications';

  // Reports
  static const String reportsCollections = '/reports/collections';
  static const String reportsLoanPortfolio = '/reports/loan-portfolio';
  static const String reportsOverdue = '/reports/overdue';
  // Interactive JSON reports
  static const String reportsMonthlyCollections = '/reports/monthly-collections';
  static const String reportsLoanPortfolioJson = '/reports/loan-portfolio-json';
  static const String reportsInterestProfit = '/reports/interest-profit';
  static const String reportsOverdueDetail = '/reports/overdue-detail';
  static const String reportsDisbursementSummary = '/reports/disbursement-summary';


  // Dashboard
  static const String dashboardAdminSummary = '/dashboard/admin-summary';
  static const String dashboardCustomerSummary = '/dashboard/customer-summary';

  // Audit
  static const String auditLogs = '/audit-logs';

  // Admin
  static const String adminViewAdmins = '/admin/view-admins';
  static const String adminConfig = '/admin/config';

  // Closed Loans
  static const String closedLoans = '/closed-loans';

  // Dues (additional)
  static const String duesToday = '/dues/today';
  static const String duesByCustomer = '/dues/by-customer';

  // Chit Funds (Admin)
  static const String chitFunds = '/chit-funds';
  static String chitFundById(String id) => '/chit-funds/$id';
  static String chitFundMembers(String id) => '/chit-funds/$id/members';
  static String chitFundMember(String id, String memberId) =>
      '/chit-funds/$id/members/$memberId';
  static String chitFundMonths(String id) => '/chit-funds/$id/months';
  static String chitFundMonthSummary(String id, String monthId) =>
      '/chit-funds/$id/months/$monthId/summary';
  static String chitFundMonthClose(String id, String monthId) =>
      '/chit-funds/$id/months/$monthId/close';
  static String chitFundAuctions(String id) => '/chit-funds/$id/auctions';
  static String chitAuction(String auctionId) => '/chit-funds/auctions/$auctionId';
  static String chitAuctionPayoutPaid(String auctionId) =>
      '/chit-funds/auctions/$auctionId/payout-paid';
  static String chitFundPayments(String id) => '/chit-funds/$id/payments';
  static String chitFundPaymentStatus(String id) => '/chit-funds/$id/payment-status';
  static String chitFundLoans(String id) => '/chit-funds/$id/loans';
  static String chitLoan(String loanId) => '/chit-funds/loans/$loanId';
  static String chitLoanRepay(String loanId) => '/chit-funds/loans/$loanId/repay';
  static String chitFundFund(String id) => '/chit-funds/$id/fund';
  static String chitFundLedger(String id) => '/chit-funds/$id/fund/ledger';
  static String chitFundReportSummary(String id) => '/chit-funds/$id/reports/summary';
  static String chitFundReportMonthly(String id) => '/chit-funds/$id/reports/monthly';
  static String chitFundReportAuctions(String id) => '/chit-funds/$id/reports/auctions';
  static String chitFundReportLoans(String id) => '/chit-funds/$id/reports/loans';
  static String chitFundReportMembers(String id) => '/chit-funds/$id/reports/members';

  // My Chit Funds (Customer)
  static const String myChits = '/my/chits';
  static String myChitById(String chitId) => '/my/chits/$chitId';
  static String myChitPayments(String chitId) => '/my/chits/$chitId/payments';
  static String myChitAuctions(String chitId) => '/my/chits/$chitId/auctions';
  static String myChitLoans(String chitId) => '/my/chits/$chitId/loans';
  static String myChitLoanDetail(String chitId, String loanId) =>
      '/my/chits/$chitId/loans/$loanId';
  static String myChitLedger(String chitId) => '/my/chits/$chitId/ledger';
}
