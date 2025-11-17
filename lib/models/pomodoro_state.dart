enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroState {
  final Duration duration;
  final Duration initialDuration;
  final bool isRunning;
  final PomodoroPhase currentPhase;
  final int completedCycles;
  final bool isPaused;

  const PomodoroState({
    required this.duration,
    required this.initialDuration,
    required this.isRunning,
    required this.currentPhase,
    required this.completedCycles,
    required this.isPaused,
  });

  factory PomodoroState.initial() {
    const workDuration = Duration(minutes: 25);
    return PomodoroState(
      duration: workDuration,
      initialDuration: workDuration,
      isRunning: false,
      currentPhase: PomodoroPhase.work,
      completedCycles: 0,
      isPaused: false,
    );
  }

  // Factory to create initial state with custom settings
  factory PomodoroState.withSettings(Duration workDuration) {
    return PomodoroState(
      duration: workDuration,
      initialDuration: workDuration,
      isRunning: false,
      currentPhase: PomodoroPhase.work,
      completedCycles: 0,
      isPaused: false,
    );
  }

  PomodoroState copyWith({
    Duration? duration,
    Duration? initialDuration,
    bool? isRunning,
    PomodoroPhase? currentPhase,
    int? completedCycles,
    bool? isPaused,
  }) {
    return PomodoroState(
      duration: duration ?? this.duration,
      initialDuration: initialDuration ?? this.initialDuration,
      isRunning: isRunning ?? this.isRunning,
      currentPhase: currentPhase ?? this.currentPhase,
      completedCycles: completedCycles ?? this.completedCycles,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  String get formattedTime {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get phaseDisplayName {
    switch (currentPhase) {
      case PomodoroPhase.work:
        return 'Focus Time';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  double get progress {
    if (initialDuration.inSeconds == 0) return 0.0;
    return (initialDuration.inSeconds - duration.inSeconds) /
        initialDuration.inSeconds;
  }
}
