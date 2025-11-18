import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Track app lifecycle state
  static AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // Update app lifecycle state
  static void updateAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  // Check if app is in background
  static bool get isAppInBackground =>
      _appLifecycleState == AppLifecycleState.paused ||
      _appLifecycleState == AppLifecycleState.detached;

  static Future<void> initializeNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Request permissions for Android 13+
    await _requestPermissions();

    // Debug: Test notification on startup
    if (kDebugMode) {
      print('🔧 DEBUG: Notification service initialized, testing...');
      // Delay test notification to ensure everything is set up
      Future.delayed(const Duration(seconds: 2), () async {
        await testNotification();
      });
    }
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Create the main pomodoro channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'pomodoro_channel',
            'Pomodoro Notifications',
            description: 'Notifications for Pomodoro timer phase completions',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        // Create test channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'test_channel',
            'Test Notifications',
            description: 'Test notification channel',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        if (kDebugMode) {
          print('✅ Notification channels created successfully');
        }
      }
    }
  }

  // Test notification function for debugging
  static Future<void> testNotification() async {
    try {
      if (kDebugMode) {
        print('🧪 Testing notification system...');
      }

      await _notificationsPlugin.show(
        999, // test ID
        'Test Notification',
        'If you see this, notifications are working!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );

      if (kDebugMode) {
        print('✅ Test notification sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Test notification failed: $e');
      }
    }
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleNotification(
    String title,
    String body,
    int seconds,
  ) async {
    if (kDebugMode) {
      print('🔍 DEBUG: App lifecycle state: $_appLifecycleState');
      print('🔍 DEBUG: isAppInBackground: $isAppInBackground');
      print('🔍 DEBUG: Attempting to show notification: $title - $body');
    }

    // Only show notifications if app is in background
    if (!isAppInBackground) {
      if (kDebugMode) {
        print('🔇 App is in foreground, skipping notification: $title - $body');
      }
      return;
    }

    if (kDebugMode) {
      print('📱 App is in background, showing notification: $title - $body');
    }

    // Android notification details
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro Notifications',
          channelDescription: 'Notifications for Pomodoro timer phases',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent:
              true, // Allow notification to show with full visibility
          autoCancel: false, // Don't auto dismiss
          ongoing: false, // Not a persistent notification
        );

    // iOS notification details
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Show notification immediately for timer completion
    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/
            1000, // unique ID based on timestamp
        title,
        body,
        notificationDetails,
      );
      if (kDebugMode) {
        print('✅ Notification shown successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show notification: $e');
      }
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
