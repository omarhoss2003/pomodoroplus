import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static AudioPlayer? _audioPlayer;
  static bool _isPlaying = false;
  static bool _shouldStop = false;

  // Initialize the audio service
  static Future<void> initialize() async {
    try {
      // Dispose any existing player first
      if (_audioPlayer != null) {
        try {
          await _audioPlayer!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing existing player during init: $e');
          }
        }
      }

      // Create fresh audio player
      _audioPlayer = AudioPlayer();
      if (kDebugMode) {
        print('🔊 Audio service with just_audio initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize audio service: $e');
      }
    }
  }

  // Play alarm sound when timer ends using just_audio
  static Future<void> playAlarmSound() async {
    try {
      // Stop and dispose any existing player first
      await stopAlarmSound();

      // Dispose the old player completely to avoid conflicts
      if (_audioPlayer != null) {
        try {
          await _audioPlayer!.dispose();
          _audioPlayer = null;
          if (kDebugMode) {
            print('🔄 Disposed old audio player');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing old player: $e');
          }
        }
      }

      // Create a fresh audio player
      try {
        _audioPlayer = AudioPlayer();
        if (kDebugMode) {
          print('✅ Created new audio player');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to create new audio player: $e');
          print('⚠️ Falling back to system sounds...');
        }
        await _fallbackAlarm();
        return;
      }

      _isPlaying = true;
      _shouldStop = false;

      if (kDebugMode) {
        print('🚨 Starting alarm sound with fresh just_audio player...');
      }

      if (_audioPlayer != null) {
        try {
          // Load and play the alarm sound
          await _audioPlayer!.setAsset('assets/sounds/alarm.wav');
          await _audioPlayer!.setVolume(1.0);
          await _audioPlayer!.setLoopMode(LoopMode.one); // Loop the sound

          // Play with vibration
          await HapticFeedback.vibrate();
          await _audioPlayer!.play();

          if (kDebugMode) {
            print('🚨 Alarm sound started successfully with just_audio');
          }
        } catch (audioError) {
          if (kDebugMode) {
            print('❌ just_audio asset loading error: $audioError');
            print('⚠️ Falling back to system sounds...');
          }
          await _fallbackAlarm();
          return;
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Audio player not initialized, using fallback');
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
        print('❌ General alarm error: $e');
      }
      // Fallback to system sound alarm
      await _fallbackAlarm();
    }
  }

  // Stop the alarm sound
  static Future<void> stopAlarmSound({Function()? onStop}) async {
    try {
      _shouldStop = true;
      _isPlaying = false;

      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      // Call the callback to update UI state if provided
      if (onStop != null) {
        onStop();
      }

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
      _isPlaying = true;
      if (kDebugMode) {
        print('🔄 Using ENHANCED fallback alarm method');
      }

      // Enhanced fallback alarm with multiple notification types
      for (int cycle = 0; cycle < 5 && !_shouldStop; cycle++) {
        // Strong vibration pattern
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));

        // System alert sound
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 200));

        // Additional vibration
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));

        // Another system sound for emphasis
        await SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 300));

        if (kDebugMode) {
          print('🔊 Fallback alarm cycle $cycle completed');
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

  // Check if alarm is currently playing
  static bool isAlarmPlaying() {
    return _isPlaying;
  }

  // Static getter for reactive updates
  static bool get isPlaying => _isPlaying;

  // Get all active alarms (not used with just_audio)
  static List<String> getActiveAlarms() {
    return [];
  }

  // Dispose audio resources
  static Future<void> dispose() async {
    try {
      // Set flags to stop any ongoing operations
      _shouldStop = true;
      _isPlaying = false;

      // Stop and dispose audio player
      if (_audioPlayer != null) {
        try {
          await _audioPlayer!.stop();
          await _audioPlayer!.dispose();
          _audioPlayer = null;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error during audio player disposal: $e');
          }
        }
      }

      if (kDebugMode) {
        print(
          '🔊 Audio service disposed - audio player stopped and cleaned up',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing audio service: $e');
      }
    }
  }
}
