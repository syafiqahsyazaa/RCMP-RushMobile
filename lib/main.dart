import 'package:flutter/material.dart';
import 'screens/helpdesk_home_screen.dart';
import 'screens/vendor_portal_screen.dart';
import 'screens/user_login_screen.dart';
import 'screens/operator_portal_screen.dart';
import 'screens/complaint/dashboard_screen.dart';
import 'screens/complaint/complaint_fill_details_screen.dart';
import 'screens/complaint/complaint_preview_review_screen.dart';
import 'screens/complaint/complaint_confirm_submissions_screen.dart';
import 'screens/complaint/complaint_submitted_screen.dart';
import 'screens/complaint/my_submissions_screen.dart';
import 'screens/complaint/ticket_detail_user_screen.dart';
import 'screens/dept_admin/admin_dashboard_screen.dart';
import 'screens/dept_admin/admin_all_tickets_screen.dart';
import 'screens/dept_admin/admin_manage_users_screen.dart';
import 'screens/dept_admin/admin_manage_vendors_screen.dart';
import 'screens/dept_admin/admin_categories_screen.dart';
import 'screens/dept_admin/admin_reports_screen.dart';
import 'screens/hod/hod_dashboard_screen.dart';
import 'screens/hod/hod_reports_screen.dart';
import 'screens/staff_login_screen.dart';
import 'screens/dept/staff_dashboard_screen.dart';
import 'screens/dept/staff_all_tickets_screen.dart';
import 'screens/dept/ticket_workspace_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
import 'package:rush_app/screens/vendor/vendor_ticket_workspace_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

// hold sesi global. Tukar email di bawah untuk menguji jabatan berbeza!
String currentLoggedInUserEmail = "syaza@gmail.com";
List<dynamic> senaraiVendorGlobalJabatanSyafiqah = [];

// Navigator key global untuk kegunaan Microsoft SSO (aad_oauth)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); //  AKTIFKAN LOCENG PHONE!
  runApp(const RushApp());
}

/// RUSH (RCMP User Helpdesk) — UniKL RCMP
///
/// Screens:
///  '/'                    -> HelpdeskHomeScreen               (department picker)
///  '/vendor'              -> VendorPortalScreen                (vendor sign in)
///  '/login'               -> UserLoginScreen                   (staff/student Microsoft SSO)
///  '/operator'            -> OperatorPortalScreen               (operator sign in)
///  '/dashboard'           -> DashboardScreen                    (quick actions + recent activity)
///  '/complaint/fill'      -> ComplaintFillDetailsScreen         (step 1)
///  '/complaint/preview'   -> ComplaintPreviewReviewScreen       (step 2)
///  '/complaint/confirm'   -> ComplaintConfirmSubmissionsScreen  (step 3)
///  '/complaint/submitted' -> ComplaintSubmittedScreen           (success)
///  '/my-submissions'      -> MySubmissionsScreen
///  '/tickets/user-detail' -> TicketDetailUserScreen              (user-facing)
///  '/admin/dashboard'     -> AdminDashboardScreen                (IT Dept admin)
///  '/admin/tickets'       -> AdminAllTicketsScreen
///  '/admin/users'         -> AdminManageUsersScreen
///  '/admin/vendors'       -> AdminManageVendorsScreen
///  '/admin/categories'    -> AdminCategoriesScreen
///  '/admin/reports'       -> AdminReportsScreen
///  '/staff/login'         -> StaffLoginScreen
///  '/staff/dashboard'     -> StaffDashboardScreen
///  '/staff/tickets'       -> StaffAllTicketsScreen
///  '/tickets/workspace'   -> TicketWorkspaceScreen               (shared admin/staff)
///  '/tickets/history'     -> TicketHistoryScreen
///  '/tickets/feedback'    -> TicketFeedbackScreen
///  '/hod/dashboard'       -> HodDashboardScreen
///  '/hod/reports'         -> HodReportsScreen
class RushApp extends StatelessWidget {
  const RushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'RUSH — UniKL RCMP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.gold,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/vendor':
            return MaterialPageRoute(
              builder: (_) => const VendorPortalScreen(),
              settings: settings,
            );
          case '/operator':
            return MaterialPageRoute(
              builder: (_) => const OperatorPortalScreen(),
              settings: settings,
            );
          case '/login':
            final department = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => UserLoginScreen(department: department),
              settings: settings,
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
              settings: settings,
            );
          case '/complaint/fill':
            return MaterialPageRoute(
              builder: (_) => const ComplaintFillDetailsScreen(),
              settings: settings,
            );
          case '/complaint/preview':
            return MaterialPageRoute(
              builder: (_) => const ComplaintPreviewReviewScreen(),
              settings: settings,
            );
          case '/complaint/confirm':
            return MaterialPageRoute(
              builder: (_) => const ComplaintConfirmSubmissionsScreen(),
              settings: settings,
            );
          case '/complaint/submitted':
            return MaterialPageRoute(
              builder: (_) => const ComplaintSubmittedScreen(),
              settings: settings,
            );
          case '/my-submissions':
            return MaterialPageRoute(
              builder: (_) => const MySubmissionsScreen(),
              settings: settings,
            );
          case '/tickets/user-detail':
            return MaterialPageRoute(
              builder: (_) => const TicketDetailUserScreen(),
              settings: settings,
            );
          case '/admin/dashboard':
            return MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(),
              settings: settings,
            );
          case '/admin/tickets':
            return MaterialPageRoute(
              builder: (_) => const AdminAllTicketsScreen(),
              settings: settings,
            );
          case '/admin/users':
            return MaterialPageRoute(
              builder: (_) => const AdminManageUsersScreen(),
              settings: settings,
            );
          case '/admin/vendors':
            return MaterialPageRoute(
              builder: (_) => const AdminManageVendorsScreen(),
              settings: settings,
            );
          case '/admin/categories':
            return MaterialPageRoute(
              builder: (_) => const AdminCategoriesScreen(),
              settings: settings,
            );
          case '/admin/reports':
            return MaterialPageRoute(
              builder: (_) => const AdminReportsScreen(),
              settings: settings,
            );
          case '/vendor/dashboard':
            return MaterialPageRoute(
              builder: (_) =>  VendorDashboardScreen(),
              settings: settings,
            );
          case '/vendor_ticket_workspace':
            return MaterialPageRoute(
              builder: (_) => const VendorTicketWorkspaceScreen(),
              settings: settings,
            );
          case '/hod/dashboard':
            return MaterialPageRoute(
              builder: (_) => const HodDashboardScreen(),
              settings: settings,
            );
          case '/hod/reports':
            return MaterialPageRoute(
              builder: (_) => const HodReportsScreen(),
              settings: settings,
            );
          case '/staff/login':
            return MaterialPageRoute(
              builder: (_) => const StaffLoginScreen(),
              settings: settings,
            );
          case '/staff/dashboard':
            return MaterialPageRoute(
              builder: (_) => const StaffDashboardScreen(),
              settings: settings,
            );
          case '/staff/tickets':
            return MaterialPageRoute(
              builder: (_) => const StaffAllTicketsScreen(),
              settings: settings,
            );
          case '/tickets/workspace':
            return MaterialPageRoute(
              builder: (_) => const TicketWorkspaceScreen(),
              settings: settings,
            );
          case '/':
          default:
            return MaterialPageRoute(
              builder: (_) => const HelpdeskHomeScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}