import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/utils.dart';

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
  
  // Initialization state
  bool _initialized = false;
  String? _initializationError;

  /// Initialize notification service
  /// Returns true if successful, false otherwise
  Future<bool> initialize() async {
    if (_initialized) {
      logger.w('NotificationService already initialized');
      return _initializationError == null;
    }

    try {
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

      _initialized = true;
      _initializationError = null;
      logger.i('NotificationService initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _initialized = false;
      _initializationError = e.toString();
      logger.e('Failed to initialize NotificationService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if notification service is initialized
  bool get isInitialized => _initialized;

  /// Get initialization error message
  String? get initializationError => _initializationError;

  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          logger.i('Notification permission granted');
          break;
        case AuthorizationStatus.provisional:
          logger.i('Notification permission provisional');
          break;
        case AuthorizationStatus.denied:
          logger.w('Notification permission denied by user');
          break;
        case AuthorizationStatus.notDetermined:
          logger.w('Notification permission not determined');
          break;
        default:
          logger.w('Unknown notification permission status: ${settings.authorizationStatus}');
      }
    } catch (e, stackTrace) {
      logger.e('Error requesting notification permission', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
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
      logger.i('Local notifications initialized');
    } catch (e, stackTrace) {
      logger.e('Error initializing local notifications', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
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
        logger.d('Created notification channel: ${channel.id}');
      }
    } catch (e, stackTrace) {
      logger.e('Error creating notification channels', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        logger.i('FCM Token obtained successfully');
        // Send token to your backend server
        if (_onTokenRefresh != null) {
          _onTokenRefresh!(token);
        }
      } else {
        logger.w('FCM Token is null');
      }
    } catch (e, stackTrace) {
      logger.e('Error getting FCM token', error: e, stackTrace: stackTrace);
      // Don't rethrow - token failure shouldn't block initialization
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    logger.i('Foreground message received: ${message.messageId}');
    
    try {
      // Show local notification
      _showLocalNotification(
        title: message.notification?.title ?? 'Coopvest',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
        channelId: _getChannelId(message.data),
      ).catchError((e) {
        logger.e('Error showing local notification', error: e);
      });

      // Call callback
      if (_onMessageReceived != null) {
        try {
          _onMessageReceived!(message);
        } catch (e) {
          logger.e('Error in onMessageReceived callback', error: e);
        }
      }
    } catch (e, stackTrace) {
      logger.e('Error handling foreground message', error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      logger.i('Background message received: ${message.messageId}');
      // Handle background message - can be extended
    } catch (e, stackTrace) {
      logger.e('Error handling background message', error: e, stackTrace: stackTrace);
    }
  }

  void _handleTokenRefresh(String token) {
    logger.i('FCM Token refreshed');
    try {
      if (_onTokenRefresh != null) {
        _onTokenRefresh!(token);
      }
    } catch (e) {
      logger.e('Error in onTokenRefresh callback', error: e);
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    logger.i('Notification tapped: ${response.payload}');
    try {
      // Navigate based on payload - implement navigation logic here
      // TODO: Integrate with navigation service
    } catch (e, stackTrace) {
      logger.e('Error handling notification tap', error: e, stackTrace: stackTrace);
    }
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
    try {
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
    } catch (e, stackTrace) {
      logger.e('Error showing local notification', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
    try {
      await _showLocalNotification(
        title: 'Loan Application Received',
        body: 'Your $loanType application for ₦${amount.formatNumber()} has been received.',
        payload: 'loan_application',
        channelId: _channelLoanId,
      );
      logger.i('Shown loan application notification');
    } catch (e, stackTrace) {
      logger.e('Error showing loan application notification', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> showGuarantorRequestNotification(String borrowerName, double loanAmount) async {
    try {
      await _showLocalNotification(
        title: 'Guarantee Request',
        body: '$borrowerName is requesting your guarantee for ₦${loanAmount.formatNumber()}.',
        payload: 'guarantor_request',
        channelId: _channelGuarantorId,
      );
      logger.i('Shown guarantor request notification');
    } catch (e, stackTrace) {
      logger.e('Error showing guarantor request notification', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> showSavingsGoalCompletedNotification(String goalName) async {
    try {
      await _showLocalNotification(
        title: 'Savings Goal Completed! 🎉',
        body: 'Congratulations! You\'ve reached your "$goalName" savings goal.',
        payload: 'savings_goal_completed',
        channelId: _channelSavingsId,
      );
      logger.i('Shown savings goal completed notification');
    } catch (e, stackTrace) {
      logger.e('Error showing savings goal notification', error: e, stackTrace: stackTrace);
    }
  }

  // Set callbacks
  void setOnMessageReceived(Function(RemoteMessage) callback) {
    _onMessageReceived = callback;
  }

  void setOnBackgroundMessage(Function(RemoteMessage) callback) {
    _onBackgroundMessage = callback;
  }

  void setOnTokenRefresh(Function(String) callback) {
    _onTokenRefresh = callback;
  }

  // Subscribe to topics
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      logger.i('Subscribed to topic: $topic');
      return true;
    } catch (e, stackTrace) {
      logger.e('Error subscribing to topic: $topic', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      logger.i('Unsubscribed from topic: $topic');
      return true;
    } catch (e, stackTrace) {
      logger.e('Error unsubscribing from topic: $topic', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Subscribe to user-specific topics
  Future<bool> subscribeToUserTopic(String userId) async {
    return await subscribeToTopic('user_$userId');
  }

  Future<bool> unsubscribeFromUserTopic(String userId) async {
    return await unsubscribeFromTopic('user_$userId');
  }

  // Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e, stackTrace) {
      logger.e('Error getting FCM token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Check notification permission status
  Future<NotificationSettings> getPermissionStatus() async {
    try {
      return await _firebaseMessaging.getNotificationSettings();
    } catch (e, stackTrace) {
      logger.e('Error getting notification permission status', error: e, stackTrace: stackTrace);
      // Return default settings on error
      return const NotificationSettings(
        authorizationStatus: AuthorizationStatus.notDetermined,
        alert: null,
        announcement: null,
        badge: null,
        carPlay: null,
        criticalAlert: null,
        lockScreen: null,
        notificationCenter: null,
        showPreviews: null,
        sound: null,
      );
    }
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

  NotificationPreferences copyWith({
    bool? loanNotifications,
    bool? guarantorNotifications,
    bool? savingsNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
  }) {
    return NotificationPreferences(
      loanNotifications: loanNotifications ?? this.loanNotifications,
      guarantorNotifications: guarantorNotifications ?? this.guarantorNotifications,
      savingsNotifications: savingsNotifications ?? this.savingsNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }
}