import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pomodoro_state.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../state/settings_notifier.dart';

// Provider to track alarm state for UI updates
final alarmStateProvider = StateProvider<bool>((ref) => false);

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  final Ref ref;

  PomodoroNotifier(this.ref) : super(PomodoroState.initial());

  void startTimer() {
    if (state.duration.inSeconds <= 0) {
      resetTimer();
      return;
    }

    state = state.copyWith(isRunning: true, isPaused: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.duration.inSeconds > 0) {
        state = state.copyWith(
          duration: Duration(seconds: state.duration.inSeconds - 1),
        );
      } else {
        // Timer finished
        _timer?.cancel();
        autoNextPhase();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  void resetTimer() {
    _timer?.cancel();
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

    // Calculate duration for next phase using settings
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

    // Send notification
    _sendPhaseNotification(nextPhase);

    // Update state with new phase
    state = state.copyWith(
      currentPhase: nextPhase,
      duration: nextDuration,
      initialDuration: nextDuration,
      completedCycles: newCompletedCycles,
    );
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

    print('🚨 TIMER ENDED - Playing alarm sound now!');

    // Update UI to show alarm is playing
    try {
      ref.read(alarmStateProvider.notifier).state = true;
    } catch (e) {
      print('Warning: Could not update alarm state provider: $e');
    }

    // Play alarm sound ALWAYS (regardless of app state)
    await AudioService.playAlarmSound();

    // Auto-reset alarm state after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      try {
        ref.read(alarmStateProvider.notifier).state = false;
      } catch (e) {
        print('Warning: Could not reset alarm state provider: $e');
      }
    });

    print('🚨 Alarm sound call completed');

    // Send notification ALWAYS (will only show if app is in background)
    NotificationService.scheduleNotification(title, body, 0);
  }

  void skipToNextPhase() {
    autoNextPhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Riverpod provider
final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (ref) => PomodoroNotifier(ref),
);
