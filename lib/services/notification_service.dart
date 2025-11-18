import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

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
        // Create the main pomodoro channel with high priority
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'pomodoro_channel',
            'Pomodoro Notifications',
            description: 'Notifications for Pomodoro timer phase completions',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
          ),
        );

        // Create ongoing notification channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'pomodoro_ongoing',
            'Pomodoro Timer',
            description: 'Ongoing Pomodoro timer notifications',
            importance: Importance.low, // Low priority for ongoing
            playSound: false,
            enableVibration: false,
            showBadge: false,
            enableLights: false,
          ),
        );

        if (kDebugMode) {
          print('✅ Notification channels created successfully');
        }
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
      print('🔍 DEBUG: Sending notification: $title - $body');
    }

    // Always send notifications - let the system decide when to show them
    // This ensures notifications work when app goes to background later
    if (kDebugMode) {
      print(
        '📱 Sending notification (app state: $_appLifecycleState): $title - $body',
      );
    }

    // Android notification details
    final AndroidNotificationDetails androidNotificationDetails =
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
              true, // Show notification even when screen is locked
          autoCancel: false, // Don't auto dismiss
          ongoing: false, // Not a persistent notification
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          usesChronometer: false,
          visibility: NotificationVisibility.public, // Show on lock screen
          category: AndroidNotificationCategory.alarm, // Treat as alarm
        );

    // iOS notification details
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    // Combined notification details
    final NotificationDetails notificationDetails = NotificationDetails(
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

  // Show ongoing notification for timer running
  static Future<void> showOngoingNotification({
    required String title,
    required String body,
    required String timeLeft,
  }) async {
    if (kDebugMode) {
      print('📱 Showing ongoing notification: $title - $body - $timeLeft');
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'pomodoro_ongoing',
          'Pomodoro Timer',
          channelDescription: 'Ongoing Pomodoro timer notifications',
          importance: Importance.low, // Low priority for ongoing notifications
          priority: Priority.low,
          playSound: false, // No sound for ongoing notifications
          enableVibration: false, // No vibration for ongoing notifications
          icon: '@mipmap/ic_launcher',
          ongoing: true, // Make it persistent
          autoCancel: false, // Don't auto dismiss
          showWhen: false, // Don't show timestamp
          usesChronometer: false,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            '$body\n\nTime remaining: $timeLeft',
            contentTitle: title,
          ),
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          colorized: true,
          color: const Color(0xFFE53E3E), // Red color
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: false, // Don't show alert for ongoing
          presentBadge: true,
          presentSound: false, // No sound for ongoing
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    try {
      await _notificationsPlugin.show(
        1, // Fixed ID for ongoing notification
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show ongoing notification: $e');
      }
    }
  }

  // Hide ongoing notification
  static Future<void> hideOngoingNotification() async {
    if (kDebugMode) {
      print('🔕 Hiding ongoing notification');
    }
    await _notificationsPlugin.cancel(1); // Cancel ongoing notification
  }
}
