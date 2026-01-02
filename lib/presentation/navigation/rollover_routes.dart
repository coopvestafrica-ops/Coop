import 'package:flutter/material.dart';
import '../screens/rollover/rollover_eligibility_screen.dart';
import '../screens/rollover/rollover_request_screen.dart';
import '../screens/rollover/guarantor_consent_screen.dart';
import '../screens/admin/admin_rollover_screens.dart';
import '../../data/models/loan_models.dart';
import '../../data/models/rollover_models.dart';

/// Rollover Routes
class RolloverRoutes {
  static const String eligibility = '/rollover/eligibility';
  static const String request = '/rollover/request';
  static const String consent = '/rollover/consent';
  static const String status = '/rollover/status';
  static const String adminList = '/admin/rollover/list';
  static const String adminDetail = '/admin/rollover/detail';

  static Map<String, Widget Function(BuildContext, dynamic)> get routes {
    return {
      eligibility: (context, args) => RolloverEligibilityScreen(
            loan: args as Loan,
          ),
      request: (context, args) => RolloverRequestScreen(
            loan: args as Loan,
          ),
      consent: (context, args) => GuarantorConsentScreen(
            rolloverId: args as String,
          ),
      status: (context, args) => RolloverStatusScreen(
            rolloverId: args as String,
          ),
      adminList: (context, args) => const AdminRolloverListScreen(),
      adminDetail: (context, args) => AdminRolloverDetailScreen(
            rolloverId: args as String,
          ),
    };
  }

  static final List<RouteInfo> _routes = [
    RouteInfo(
      path: eligibility,
      name: 'Rollover Eligibility',
      description: 'Check if a loan is eligible for rollover',
      screen: const RolloverEligibilityScreen(loan: Loan(
        id: 'demo',
        userId: 'demo',
        amount: 100000,
        tenure: 6,
        interestRate: 7.0,
        monthlyRepayment: 18333,
        totalRepayment: 110000,
        status: 'active',
        guarantorsAccepted: 3,
        guarantorsRequired: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )),
    ),
    RouteInfo(
      path: request,
      name: 'Request Rollover',
      description: 'Submit a rollover request',
      screen: const RolloverRequestScreen(loan: Loan(
        id: 'demo',
        userId: 'demo',
        amount: 100000,
        tenure: 6,
        interestRate: 7.0,
        monthlyRepayment: 18333,
        totalRepayment: 110000,
        status: 'active',
        guarantorsAccepted: 3,
        guarantorsRequired: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )),
    ),
    RouteInfo(
      path: consent,
      name: 'Guarantor Consent',
      description: 'Track guarantor consent status',
      screen: const GuarantorConsentScreen(rolloverId: 'demo'),
    ),
    RouteInfo(
      path: status,
      name: 'Rollover Status',
      description: 'View rollover request status',
      screen: const RolloverStatusScreen(rolloverId: 'demo'),
    ),
    RouteInfo(
      path: adminList,
      name: 'Admin Rollover List',
      description: 'View all rollover requests',
      screen: const AdminRolloverListScreen(),
    ),
    RouteInfo(
      path: adminDetail,
      name: 'Admin Rollover Detail',
      description: 'Review and approve/reject rollover',
      screen: const AdminRolloverDetailScreen(rolloverId: 'demo'),
    ),
  ];

  static List<RouteInfo> get allRoutes => _routes;
}

/// Route Information for documentation
class RouteInfo {
  final String path;
  final String name;
  final String description;
  final Widget screen;

  RouteInfo({
    required this.path,
    required this.name,
    required this.description,
    required this.screen,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'description': description,
      };
}

/// Navigation Helper for Rollover Screens
class RolloverNavigator {
  /// Navigate to eligibility check screen
  static Future<void> toEligibility(BuildContext context, Loan loan) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.eligibility,
      arguments: loan,
    );
  }

  /// Navigate to rollover request screen
  static Future<void> toRequest(BuildContext context, Loan loan) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.request,
      arguments: loan,
    );
  }

  /// Navigate to guarantor consent screen
  static Future<void> toConsent(BuildContext context, String rolloverId) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.consent,
      arguments: rolloverId,
    );
  }

  /// Navigate to rollover status screen
  static Future<void> toStatus(BuildContext context, String rolloverId) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.status,
      arguments: rolloverId,
    );
  }

  /// Navigate to admin rollover list
  static Future<void> toAdminList(BuildContext context) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.adminList,
    );
  }

  /// Navigate to admin rollover detail
  static Future<void> toAdminDetail(BuildContext context, String rolloverId) {
    return Navigator.pushNamed(
      context,
      RolloverRoutes.adminDetail,
      arguments: rolloverId,
    );
  }
}
