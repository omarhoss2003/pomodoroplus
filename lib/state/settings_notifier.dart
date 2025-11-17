import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsNotifier extends StateNotifier<PomodoroSettings> {
  SettingsNotifier() : super(PomodoroSettings.defaults) {
    _loadSettings();
  }

  // Keys for SharedPreferences
  static const String _workMinutesKey = 'work_minutes';
  static const String _shortBreakMinutesKey = 'short_break_minutes';
  static const String _longBreakMinutesKey = 'long_break_minutes';

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final workMinutes =
          prefs.getInt(_workMinutesKey) ??
          PomodoroSettings.defaults.workMinutes;
      final shortBreakMinutes =
          prefs.getInt(_shortBreakMinutesKey) ??
          PomodoroSettings.defaults.shortBreakMinutes;
      final longBreakMinutes =
          prefs.getInt(_longBreakMinutesKey) ??
          PomodoroSettings.defaults.longBreakMinutes;

      state = PomodoroSettings(
        workMinutes: workMinutes,
        shortBreakMinutes: shortBreakMinutes,
        longBreakMinutes: longBreakMinutes,
      );

      print(
        '📱 Settings loaded: Work: ${state.workMinutes}min, Short: ${state.shortBreakMinutes}min, Long: ${state.longBreakMinutes}min',
      );
    } catch (e) {
      print('⚠️ Error loading settings: $e');
      // If loading fails, keep default settings
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_workMinutesKey, state.workMinutes);
      await prefs.setInt(_shortBreakMinutesKey, state.shortBreakMinutes);
      await prefs.setInt(_longBreakMinutesKey, state.longBreakMinutes);

      print(
        '💾 Settings saved: Work: ${state.workMinutes}min, Short: ${state.shortBreakMinutes}min, Long: ${state.longBreakMinutes}min',
      );
    } catch (e) {
      print('⚠️ Error saving settings: $e');
    }
  }

  void updateWorkMinutes(int minutes) {
    if (minutes >= 1 && minutes <= 90) {
      state = state.copyWith(workMinutes: minutes);
      _saveSettings();
    }
  }

  void updateShortBreakMinutes(int minutes) {
    if (minutes >= 1 && minutes <= 30) {
      state = state.copyWith(shortBreakMinutes: minutes);
      _saveSettings();
    }
  }

  void updateLongBreakMinutes(int minutes) {
    if (minutes >= 1 && minutes <= 60) {
      state = state.copyWith(longBreakMinutes: minutes);
      _saveSettings();
    }
  }

  Future<void> resetToDefaults() async {
    state = PomodoroSettings.defaults;
    await _saveSettings();
    print('🔄 Settings reset to defaults');
  }
}

// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, PomodoroSettings>(
      (ref) => SettingsNotifier(),
    );
