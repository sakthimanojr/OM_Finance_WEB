import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_login_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/customer_list_screen.dart';
import '../../screens/admin/new_customer_screen.dart';
import '../../screens/admin/customer_detail_screen.dart';
import '../../screens/admin/new_loan_screen.dart';
import '../../screens/admin/loan_detail_screen.dart';
import '../../screens/admin/dues_screen.dart';
import '../../screens/admin/reports_screen.dart';
import '../../screens/admin/admin_management_screen.dart';
import '../../screens/admin/audit_log_screen.dart';
import '../../screens/admin/closed_loans_screen.dart';
import '../../screens/admin/admin_payments_screen.dart';
import '../../screens/admin/loan_list_screen.dart';
import '../../screens/shared/notification_history_screen.dart';
import '../../screens/customer/customer_dashboard_screen.dart';
import '../../screens/customer/customer_loan_list_screen.dart';
import '../../screens/customer/customer_loan_detail_screen.dart';
import '../../screens/customer/payment_screen.dart';
import '../../screens/customer/customer_profile_screen.dart';
import '../../screens/customer/my_payments_screen.dart';

// Chit Fund Screens
import '../../screens/admin/chit_fund_list_screen.dart';
import '../../screens/admin/create_chit_fund_screen.dart';
import '../../screens/admin/chit_fund_detail_screen.dart';
import '../../screens/admin/chit_members_screen.dart';
import '../../screens/admin/chit_monthly_payments_screen.dart';
import '../../screens/admin/chit_auction_history_screen.dart';
import '../../screens/admin/chit_monthly_auction_screen.dart';
import '../../screens/admin/chit_loans_screen.dart';
import '../../screens/admin/chit_fund_ledger_screen.dart';
import '../../screens/admin/chit_fund_reports_screen.dart';
import '../../screens/customer/my_chits_screen.dart';
import '../../screens/customer/my_chit_loan_detail_screen.dart';
import '../../screens/admin/daily_records_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = ['/login', '/otp-login', '/forgot-password'].contains(state.matchedLocation);

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) {
        return authState.user!.isAdmin ? '/admin/dashboard' : '/customer/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/otp-login', builder: (context, state) => const OtpLoginScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      // Admin routes
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(
        path: '/admin/customers',
        builder: (context, state) => CustomerListScreen(status: state.uri.queryParameters['status']),
      ),
      GoRoute(path: '/admin/customers/new', builder: (context, state) => const NewCustomerScreen()),
      GoRoute(
        path: '/admin/customers/:id',
        builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/loans/new',
        builder: (context, state) => NewLoanScreen(customerId: state.uri.queryParameters['customerId']),
      ),
      GoRoute(
        path: '/admin/loans/:id',
        builder: (context, state) => LoanDetailScreen(loanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/dues',
        builder: (context, state) => DuesScreen(initialTab: state.uri.queryParameters['tab']),
      ),
      GoRoute(
        path: '/admin/loans',
        builder: (context, state) => LoanListScreen(status: state.uri.queryParameters['status']),
      ),
      GoRoute(path: '/admin/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/admin/management', builder: (context, state) => const AdminManagementScreen()),
      GoRoute(path: '/admin/audit-logs', builder: (context, state) => const AuditLogScreen()),
      GoRoute(path: '/admin/closed-loans', builder: (context, state) => const ClosedLoansScreen()),
      GoRoute(path: '/admin/daily-records', builder: (context, state) => const DailyRecordsScreen()),
      GoRoute(
        path: '/admin/payments',
        builder: (context, state) => AdminPaymentsScreen(month: state.uri.queryParameters['month']),
      ),
      GoRoute(
        path: '/admin/customers/:id/notifications',
        builder: (context, state) => NotificationHistoryScreen(
          customerId: state.pathParameters['id']!,
          customerName: state.uri.queryParameters['name'],
        ),
      ),

      // Chit Fund Admin Routes
      GoRoute(path: '/admin/chit-funds', builder: (context, state) => const ChitFundListScreen()),
      GoRoute(path: '/admin/chit-funds/new', builder: (context, state) => const CreateChitFundScreen()),
      GoRoute(
        path: '/admin/chit-funds/:id',
        builder: (context, state) => ChitFundDetailScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/members',
        builder: (context, state) => ChitMembersScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/payments',
        builder: (context, state) => ChitMonthlyPaymentsScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/auctions',
        builder: (context, state) => ChitAuctionHistoryScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/auctions/new',
        builder: (context, state) => ChitMonthlyAuctionScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/loans',
        builder: (context, state) => ChitLoansScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/fund',
        builder: (context, state) => ChitFundLedgerScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/chit-funds/:id/reports',
        builder: (context, state) => ChitFundReportsScreen(chitId: state.pathParameters['id']!),
      ),


      // Customer routes
      GoRoute(path: '/customer/dashboard', builder: (context, state) => const CustomerDashboardScreen()),
      GoRoute(path: '/customer/loans', builder: (context, state) => const CustomerLoanListScreen()),
      GoRoute(
        path: '/customer/loans/:id',
        builder: (context, state) => CustomerLoanDetailScreen(loanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/pay/:dueId',
        builder: (context, state) => PaymentScreen(
          dueId: state.pathParameters['dueId']!,
          amount: num.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0,
          dueNumber: int.tryParse(state.uri.queryParameters['dueNumber'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/customer/profile', builder: (context, state) => const CustomerProfileScreen()),
      GoRoute(path: '/customer/payments', builder: (context, state) => const MyPaymentsScreen()),

      // Chit Fund Customer Routes
      GoRoute(path: '/customer/chits', builder: (context, state) => const MyChitsScreen()),
      GoRoute(
        path: '/customer/chits/:id',
        builder: (context, state) => MyChitDetailScreen(chitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/chits/:id/loans/:loanId',
        builder: (context, state) => MyChitLoanDetailScreen(
          chitId: state.pathParameters['id']!,
          loanId: state.pathParameters['loanId']!,
        ),
      ),

    ],
  );
});
