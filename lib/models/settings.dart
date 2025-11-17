class PomodoroSettings {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const PomodoroSettings({
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  // Default settings
  static const PomodoroSettings defaults = PomodoroSettings(
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    return PomodoroSettings(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    );
  }

  Duration get workDuration => Duration(minutes: workMinutes);
  Duration get shortBreakDuration => Duration(minutes: shortBreakMinutes);
  Duration get longBreakDuration => Duration(minutes: longBreakMinutes);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroSettings &&
        other.workMinutes == workMinutes &&
        other.shortBreakMinutes == shortBreakMinutes &&
        other.longBreakMinutes == longBreakMinutes;
  }

  @override
  int get hashCode =>
      Object.hash(workMinutes, shortBreakMinutes, longBreakMinutes);

  @override
  String toString() {
    return 'PomodoroSettings(work: ${workMinutes}m, shortBreak: ${shortBreakMinutes}m, longBreak: ${longBreakMinutes}m)';
  }
}
