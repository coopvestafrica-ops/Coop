import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

/// Deep Linking Service - Handles QR code and URL deep links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  // Stream controller for deep link events
  final _deepLinkStream = StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkStream.stream;

  // Pending deep link
  String? _pendingDeepLink;
  String? get pendingDeepLink => _pendingDeepLink;

  // Initialize deep link handling
  Future<void> initialize() async {
    // Handle initial link (app was closed)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial deep link: $e');
    }

    // Handle link while app is running
    linkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(String link) {
    print('Deep link received: $link');

    // Store pending link
    _pendingDeepLink = link;

    // Parse and handle the link
    final uri = Uri.parse(link);
    final path = uri.path;
    final params = uri.queryParameters;

    // Determine action based on path
    switch (path) {
      case '/loan/guarantee':
        // Handle loan guarantee request
        final loanId = params['loan_id'];
        final borrowerName = params['borrower'];
        final loanAmount = double.tryParse(params['amount'] ?? '0');
        final loanType = params['loan_type'];
        final tenor = int.tryParse(params['tenor'] ?? '0');

        if (loanId != null && borrowerName != null && loanAmount != null) {
          _deepLinkStream.add('guarantee:$loanId:$borrowerName:$loanAmount:$loanType:$tenor');
        }
        break;

      case '/loan/view':
        // Handle loan viewing
        final loanId = params['loan_id'];
        if (loanId != null) {
          _deepLinkStream.add('view_loan:$loanId');
        }
        break;

      case '/profile/view':
        // Handle profile view
        final userId = params['user_id'];
        if (userId != null) {
          _deepLinkStream.add('view_profile:$userId');
        }
        break;

      case '/savings/goal':
        // Handle savings goal
        final goalId = params['goal_id'];
        if (goalId != null) {
          _deepLinkStream.add('view_goal:$goalId');
        }
        break;

      case '/wallet/receive':
        // Handle wallet receive request
        final userId = params['user_id'];
        if (userId != null) {
          _deepLinkStream.add('receive_funds:$userId');
        }
        break;

      default:
        // Unknown link type
        _deepLinkStream.add('unknown:$link');
    }
  }

  // Clear pending link after navigation
  void clearPendingLink() {
    _pendingDeepLink = null;
  }

  // Generate QR code data for loan guarantee request
  static String generateLoanGuaranteeQR({
    required String loanId,
    required String borrowerName,
    required double loanAmount,
    required String loanType,
    required int tenor,
  }) {
    final baseUrl = 'https://coopvest.africa';
    final path = '/loan/guarantee';
    final params = {
      'loan_id': loanId,
      'borrower': borrowerName,
      'amount': loanAmount.toString(),
      'loan_type': loanType,
      'tenor': tenor.toString(),
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$baseUrl$path?$queryString';
  }

  // Generate QR code data for receiving funds
  static String generateReceiveFundsQR({
    required String userId,
    required String userName,
  }) {
    final baseUrl = 'https://coopvest.africa';
    final path = '/wallet/receive';
    final params = {
      'user_id': userId,
      'name': userName,
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$baseUrl$path?$queryString';
  }

  // Generate profile sharing QR
  static String generateProfileQR({
    required String userId,
  }) {
    final baseUrl = 'https://coopvest.africa';
    final path = '/profile/view';
    final params = {
      'user_id': userId,
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$baseUrl$path?$queryString';
  }

  // Parse deep link and return navigation data
  static DeepLinkData parseDeepLink(String link) {
    final uri = Uri.parse(link);
    final path = uri.path;
    final params = uri.queryParameters;

    switch (path) {
      case '/loan/guarantee':
        return DeepLinkData(
          type: DeepLinkType.guaranteeRequest,
          path: path,
          params: params,
          screen: '/guarantor-verification',
        );

      case '/loan/view':
        return DeepLinkData(
          type: DeepLinkType.viewLoan,
          path: path,
          params: params,
          screen: '/loan-details',
        );

      case '/profile/view':
        return DeepLinkData(
          type: DeepLinkType.viewProfile,
          path: path,
          params: params,
          screen: '/profile',
        );

      case '/savings/goal':
        return DeepLinkData(
          type: DeepLinkType.viewSavingsGoal,
          path: path,
          params: params,
          screen: '/savings-goal',
        );

      case '/wallet/receive':
        return DeepLinkData(
          type: DeepLinkType.receiveFunds,
          path: path,
          params: params,
          screen: '/wallet',
        );

      default:
        return DeepLinkData(
          type: DeepLinkType.unknown,
          path: path,
          params: params,
          screen: '/home',
        );
    }
  }

  // Dispose
  void dispose() {
    _deepLinkStream.close();
  }
}

/// Deep Link Types
enum DeepLinkType {
  guaranteeRequest,
  viewLoan,
  viewProfile,
  viewSavingsGoal,
  receiveFunds,
  unknown,
}

/// Deep Link Data
class DeepLinkData {
  final DeepLinkType type;
  final String path;
  final Map<String, String> params;
  final String screen;

  DeepLinkData({
    required this.type,
    required this.path,
    required this.params,
    required this.screen,
  });

  String? get loanId => params['loan_id'];
  String? get userId => params['user_id'];
  String? get borrowerName => params['borrower'];
  double? get loanAmount => double.tryParse(params['amount'] ?? '0');
  String? get loanType => params['loan_type'];
  int? get tenor => int.tryParse(params['tenor'] ?? '0');
  String? get goalId => params['goal_id'];
}

/// Deep Link Navigator - Helper for navigating based on deep links
class DeepLinkNavigator {
  static void navigateToScreen(BuildContext context, DeepLinkData data) {
    switch (data.type) {
      case DeepLinkType.guaranteeRequest:
        if (data.loanId != null && data.borrowerName != null && data.loanAmount != null) {
          // Navigate to guarantor verification screen
          Navigator.of(context).pushNamed(
            '/guarantor-verification',
            arguments: {
              'loanId': data.loanId,
              'borrowerName': data.borrowerName,
              'loanAmount': data.loanAmount,
              'loanType': data.loanType ?? 'Quick Loan',
              'loanTenor': data.tenor ?? 4,
            },
          );
        }
        break;

      case DeepLinkType.viewLoan:
        if (data.loanId != null) {
          Navigator.of(context).pushNamed(
            '/loan-details',
            arguments: {'loanId': data.loanId},
          );
        }
        break;

      case DeepLinkType.viewProfile:
        if (data.userId != null) {
          Navigator.of(context).pushNamed(
            '/profile',
            arguments: {'userId': data.userId},
          );
        }
        break;

      case DeepLinkType.viewSavingsGoal:
        if (data.goalId != null) {
          Navigator.of(context).pushNamed(
            '/savings-goal',
            arguments: {'goalId': data.goalId},
          );
        }
        break;

      case DeepLinkType.receiveFunds:
        Navigator.of(context).pushNamed('/wallet');
        break;

      case DeepLinkType.unknown:
      default:
        Navigator.of(context).pushNamed('/home');
        break;
    }
  }
}
