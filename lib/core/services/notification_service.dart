import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification Service - Handles Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Notification channels
  static const String _channelLoanId = 'loan_notifications';
  static const String _channelGuarantorId = 'guarantor_notifications';
  static const String _channelSavingsId = 'savings_notifications';
  static const String _channelGeneralId = 'general_notifications';

  // Callbacks
  Function(RemoteMessage)? _onMessageReceived;
  Function(RemoteMessage)? _onBackgroundMessage;
  Function(String)? _onTokenRefresh;

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create notification channels
    await _createNotificationChannels();

    // Get FCM token
    await _getFCMToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Notification permission provisional');
    } else {
      print('Notification permission denied');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _createNotificationChannels() async {
    const androidChannels = [
      AndroidNotificationChannel(
        _channelLoanId,
        'Loan Notifications',
        description: 'Notifications about your loan applications and repayments',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _channelGuarantorId,
        'Guarantor Requests',
        description: 'Notifications when someone requests your guarantee',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _channelSavingsId,
        'Savings Updates',
        description: 'Notifications about your savings goals and contributions',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _channelGeneralId,
        'General Notifications',
        description: 'General app notifications and updates',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in androidChannels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      // Send token to your backend server
      if (token != null && _onTokenRefresh != null) {
        _onTokenRefresh!(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.messageId}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Coopvest',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      channelId: _getChannelId(message.data),
    );

    // Call callback
    if (_onMessageReceived != null) {
      _onMessageReceived!(message);
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message received: ${message.messageId}');
    // Handle background message
  }

  void _handleTokenRefresh(String token) {
    print('FCM Token refreshed: $token');
    if (_onTokenRefresh != null) {
      _onTokenRefresh!(token);
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate based on payload
  }

  String _getChannelId(Map<String, String> data) {
    final type = data['type'] ?? '';
    switch (type) {
      case 'loan':
        return _channelLoanId;
      case 'guarantor':
        return _channelGuarantorId;
      case 'savings':
        return _channelSavingsId;
      default:
        return _channelGeneralId;
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    required String channelId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'coopvest_notifications',
      'Coopvest Notifications',
      channelId: 'coopvest_notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Notification types
  static const int _loanApplicationId = 1001;
  static const int _loanApprovedId = 1002;
  static const int _loanRepaymentId = 1003;
  static const int _guarantorRequestId = 2001;
  static const int _guarantorConfirmedId = 2002;
  static const int _savingsGoalId = 3001;
  static const int _savingsContributionId = 3002;

  // Show specific notifications
  Future<void> showLoanApplicationNotification(String loanType, double amount) async {
    await _showLocalNotification(
      title: 'Loan Application Received',
      body: 'Your $loanType application for ₦${amount.formatNumber()} has been received.',
      payload: 'loan_application',
      channelId: _channelLoanId,
    );
  }

  Future<void> showGuarantorRequestNotification(String borrowerName, double loanAmount) async {
    await _showLocalNotification(
      title: 'Guarantee Request',
      body: '$borrowerName is requesting your guarantee for ₦${loanAmount.formatNumber()}.',
      payload: 'guarantor_request',
      channelId: _channelGuarantorId,
    );
  }

  Future<void> showSavingsGoalCompletedNotification(String goalName) async {
    await _showLocalNotification(
      title: 'Savings Goal Completed! 🎉',
      body: 'Congratulations! You\'ve reached your "$goalName" savings goal.',
      payload: 'savings_goal_completed',
      channelId: _channelSavingsId,
    );
  }

  // Set callbacks
  void setOnMessageReceived(Function(RemoteMessage) callback) {
    _onMessageReceived = callback;
  }

  void setOnTokenRefresh(Function(String) callback) {
    _onTokenRefresh = callback;
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Subscribe to user-specific topics
  Future<void> subscribeToUserTopic(String userId) async {
    await subscribeToTopic('user_$userId');
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    await unsubscribeFromTopic('user_$userId');
  }
}

/// Notification Preferences
class NotificationPreferences {
  final bool loanNotifications;
  final bool guarantorNotifications;
  final bool savingsNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  const NotificationPreferences({
    this.loanNotifications = true,
    this.guarantorNotifications = true,
    this.savingsNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'loan_notifications': loanNotifications,
      'guarantor_notifications': guarantorNotifications,
      'savings_notifications': savingsNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      loanNotifications: json['loan_notifications'] ?? true,
      guarantorNotifications: json['guarantor_notifications'] ?? true,
      savingsNotifications: json['savings_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
    );
  }
}
