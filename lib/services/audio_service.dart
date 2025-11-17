import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';

class AudioService {
  static const int alarmId = 42; // Unique ID for our alarm
  static bool _isPlaying = false; // Track if alarm is currently playing
  static bool _shouldStop = false; // Flag to stop the alarm

  // Initialize the audio service with alarm package
  static Future<void> initialize() async {
    try {
      await Alarm.init();
      if (kDebugMode) {
        print('🔊 Audio service with Alarm package initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize audio service: $e');
      }
    }
  }

  // Play alarm sound when timer ends using the alarm package
  static Future<void> playAlarmSound() async {
    try {
      // Stop any existing alarm first
      await stopAlarmSound();

      _isPlaying = true;
      _shouldStop = false;

      if (kDebugMode) {
        print('🚨 Starting ALARM package alarm sound...');
      }

      // Create alarm settings using built-in alarm sound from the alarm package
      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: DateTime.now().add(
          const Duration(milliseconds: 100),
        ), // Start almost immediately
        assetAudioPath:
            'assets/sounds/alarm.wav', // Use the WAV file you provided
        loopAudio: true, // Loop the alarm
        vibrate: true,
        volume: 1.0, // Maximum volume
        fadeDuration: 0.0, // No fade, immediate start
        notificationTitle: 'Pomodoro Timer',
        notificationBody: 'Timer finished! 🍅',
        enableNotificationOnKill: false,
      );

      // Set the alarm
      bool success = await Alarm.set(alarmSettings: alarmSettings);

      if (success && kDebugMode) {
        print('🚨 ALARM package alarm started successfully');
      } else {
        if (kDebugMode) {
          print('⚠️ ALARM package failed, using fallback');
        }
        await _fallbackAlarm();
        return;
      }

      // Auto-stop the alarm after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        stopAlarmSound();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ ALARM package error: $e');
      }
      // Fallback to aggressive system sound alarm
      await _fallbackAlarm();
    }
  }

  // Stop the alarm sound
  static Future<void> stopAlarmSound() async {
    try {
      _shouldStop = true;
      _isPlaying = false;

      await Alarm.stop(alarmId);
      if (kDebugMode) {
        print('🔇 Alarm sound stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop alarm sound: $e');
      }
    }
  }

  // Fallback alarm using system sounds and vibration
  static Future<void> _fallbackAlarm() async {
    try {
      if (kDebugMode) {
        print('🔄 Using ENHANCED fallback alarm method');
      }

      // Much more controlled fallback alarm with stop mechanism
      for (int cycle = 0; cycle < 3 && !_shouldStop; cycle++) {
        // Moderate alarm pattern - not as aggressive
        for (int i = 0; i < 5 && !_shouldStop; i++) {
          await SystemSound.play(SystemSoundType.alert);
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 400));
        }

        // Brief pause between cycles
        if (cycle < 2 && !_shouldStop) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      _isPlaying = false;

      if (kDebugMode) {
        print('🔄 Fallback alarm completed');
      }
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) {
        print('❌ Even fallback alarm failed: $e');
      }
    }
  }

  // Test alarm sound (for debugging)
  static Future<void> testAlarm() async {
    if (kDebugMode) {
      print('🧪 Testing alarm sound...');
      await playAlarmSound();

      // Stop test alarm after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        stopAlarmSound();
      });
    }
  }

  // Check if alarm is currently playing
  static bool isAlarmPlaying() {
    return _isPlaying || Alarm.hasAlarm();
  }

  // Get all active alarms
  static List<AlarmSettings> getActiveAlarms() {
    return Alarm.getAlarms();
  }

  // Dispose audio resources
  static Future<void> dispose() async {
    try {
      // Stop any active alarms
      await Alarm.stopAll();
      if (kDebugMode) {
        print('🔊 Audio service disposed - all alarms stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing audio service: $e');
      }
    }
  }
}
