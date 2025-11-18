import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pomodoro_state.dart';
import '../models/settings.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../state/settings_notifier.dart';
import '../state/tasks_notifier.dart';

// Provider to track alarm state for UI updates
final alarmStateProvider = StateProvider<bool>((ref) => false);

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  final Ref ref;
  bool _isNaturalEnd = false; // Track if timer ended naturally

  PomodoroNotifier(this.ref) : super(PomodoroState.initial()) {
    // Initialize with current settings and listen to changes
    _initializeWithSettings();
    // Listen to settings changes to update timer automatically
    ref.listen<PomodoroSettings>(settingsProvider, (previous, next) {
      _onSettingsChanged(previous, next);
    });
  }

  // Initialize timer with current settings
  void _initializeWithSettings() {
    final settings = ref.read(settingsProvider);
    final workDuration = settings.workDuration;

    state = state.copyWith(
      duration: workDuration,
      initialDuration: workDuration,
    );
  }

  // Called when settings change
  void _onSettingsChanged(PomodoroSettings? previous, PomodoroSettings next) {
    // Only update if timer is not running
    if (!state.isRunning) {
      Duration newDuration;
      switch (state.currentPhase) {
        case PomodoroPhase.work:
          newDuration = next.workDuration;
          break;
        case PomodoroPhase.shortBreak:
          newDuration = next.shortBreakDuration;
          break;
        case PomodoroPhase.longBreak:
          newDuration = next.longBreakDuration;
          break;
      }

      state = state.copyWith(
        duration: newDuration,
        initialDuration: newDuration,
      );
    }
  }

  void startTimer() {
    if (state.duration.inSeconds <= 0) {
      resetTimer();
      return;
    }

    state = state.copyWith(isRunning: true, isPaused: false);

    // Show ongoing notification when timer starts
    _showOngoingNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.duration.inSeconds > 0) {
        state = state.copyWith(
          duration: Duration(seconds: state.duration.inSeconds - 1),
        );

        // Update ongoing notification every 30 seconds to avoid too many updates
        if (state.duration.inSeconds % 30 == 0) {
          _showOngoingNotification();
        }
      } else {
        // Timer finished naturally
        _timer?.cancel();
        // Hide ongoing notification when timer ends
        NotificationService.hideOngoingNotification();
        _isNaturalEnd = true; // Mark as natural end
        autoNextPhase();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
    // Hide ongoing notification when paused
    NotificationService.hideOngoingNotification();
  }

  void resetTimer() {
    _timer?.cancel();
    // Hide ongoing notification when reset
    NotificationService.hideOngoingNotification();

    final settings = ref.read(settingsProvider);

    // Get duration for current phase based on settings
    Duration phaseDuration;
    switch (state.currentPhase) {
      case PomodoroPhase.work:
        phaseDuration = settings.workDuration;
        break;
      case PomodoroPhase.shortBreak:
        phaseDuration = settings.shortBreakDuration;
        break;
      case PomodoroPhase.longBreak:
        phaseDuration = settings.longBreakDuration;
        break;
    }

    state = state.copyWith(
      duration: phaseDuration,
      initialDuration: phaseDuration,
      isRunning: false,
      isPaused: false,
    );
  }

  void autoNextPhase() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: false);

    // Determine next phase
    PomodoroPhase nextPhase;
    int newCompletedCycles = state.completedCycles;

    switch (state.currentPhase) {
      case PomodoroPhase.work:
        newCompletedCycles++;
        // After 4 work cycles, take a long break
        if (newCompletedCycles % 4 == 0) {
          nextPhase = PomodoroPhase.longBreak;
        } else {
          nextPhase = PomodoroPhase.shortBreak;
        }
        break;
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        nextPhase = PomodoroPhase.work;
        break;
    }

    // Calculate duration for next phase using current settings
    final settings = ref.read(settingsProvider);
    Duration nextDuration;
    switch (nextPhase) {
      case PomodoroPhase.work:
        nextDuration = settings.workDuration;
        break;
      case PomodoroPhase.shortBreak:
        nextDuration = settings.shortBreakDuration;
        break;
      case PomodoroPhase.longBreak:
        nextDuration = settings.longBreakDuration;
        break;
    }

    // Send notification and play alarm ONLY if timer ended naturally
    if (_isNaturalEnd) {
      _sendPhaseNotification(nextPhase);
    }

    // Handle task progression when work session completes (only for natural completion)
    if (state.currentPhase == PomodoroPhase.work && _isNaturalEnd) {
      _handleTaskProgression();
    }

    // Update state with new phase
    state = state.copyWith(
      currentPhase: nextPhase,
      duration: nextDuration,
      initialDuration: nextDuration,
      completedCycles: newCompletedCycles,
    );
  }

  // Handle task progression when a work session completes
  void _handleTaskProgression() async {
    try {
      final tasksNotifier = ref.read(tasksProvider.notifier);
      await tasksNotifier.addPomodoroToCurrentTask();

      if (kDebugMode) {
        print('🎯 Task progression updated after work session completion');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating task progression: $e');
      }
    }
  }

  void _sendPhaseNotification(PomodoroPhase nextPhase) async {
    String title;
    String body;

    switch (state.currentPhase) {
      case PomodoroPhase.work:
        if (nextPhase == PomodoroPhase.longBreak) {
          title = 'Great Job! 🎉';
          body = 'You completed 4 focus sessions! Time for a long break.';
        } else {
          title = 'Focus Session Complete! ✅';
          body = 'Time for a short break. You deserve it!';
        }
        break;
      case PomodoroPhase.shortBreak:
        title = 'Break Over! 💪';
        body = 'Ready to get back to focused work?';
        break;
      case PomodoroPhase.longBreak:
        title = 'Long Break Complete! 🚀';
        body = 'Feeling refreshed? Let\'s start a new cycle!';
        break;
    }

    // This method should only be called for natural timer completion
    // Send notification
    try {
      await NotificationService.scheduleNotification(title, body, 0);

      // Also schedule a delayed notification in case the first one is missed
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await NotificationService.scheduleNotification(
            '$title (Reminder)',
            body,
            0,
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Failed to send reminder notification: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send immediate notification: $e');
      }
    }

    // Update UI to show alarm is playing (only for natural completion)
    try {
      ref.read(alarmStateProvider.notifier).state = true;
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not update alarm state provider: $e');
      }
    }

    // Play alarm sound ALWAYS (regardless of app state) - only for natural completion
    await AudioService.playAlarmSound();

    // Auto-reset alarm state after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      try {
        ref.read(alarmStateProvider.notifier).state = false;
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not reset alarm state provider: $e');
        }
      }
    });

    // Reset the flag for next time
    _isNaturalEnd = false;
  }

  void skipToNextPhase() {
    // Ensure timer stops
    _timer?.cancel();

    // Mark as manual skip (no alarm should play)
    _isNaturalEnd = false;

    // Hide ongoing notification when skipping
    NotificationService.hideOngoingNotification();

    // Skip to next phase without alarm/notification
    autoNextPhase();

    if (kDebugMode) {
      print('⏭️ Phase skipped manually - no alarm triggered');
    }
  }

  void _showOngoingNotification() {
    String phaseTitle;
    String phaseEmoji;

    switch (state.currentPhase) {
      case PomodoroPhase.work:
        phaseTitle = 'Focus Session';
        phaseEmoji = '🎯';
        break;
      case PomodoroPhase.shortBreak:
        phaseTitle = 'Short Break';
        phaseEmoji = '☕';
        break;
      case PomodoroPhase.longBreak:
        phaseTitle = 'Long Break';
        phaseEmoji = '🌱';
        break;
    }

    // Format time remaining
    final minutes = state.duration.inMinutes;
    final seconds = state.duration.inSeconds % 60;
    final timeLeft =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    NotificationService.showOngoingNotification(
      title: '$phaseEmoji $phaseTitle in Progress',
      body: 'Stay focused and keep going!',
      timeLeft: timeLeft,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Hide ongoing notification when disposing
    NotificationService.hideOngoingNotification();
    super.dispose();
  }
}

// Riverpod provider
final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (ref) => PomodoroNotifier(ref),
);
