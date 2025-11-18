import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/pomodoro_notifier.dart';
import '../models/pomodoro_state.dart';
import '../services/audio_service.dart';

class ControlButtons extends ConsumerStatefulWidget {
  const ControlButtons({super.key});

  @override
  ConsumerState<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends ConsumerState<ControlButtons>
    with TickerProviderStateMixin {
  late AnimationController _mainButtonController;
  late AnimationController _resetButtonController;
  late AnimationController _skipButtonController;

  @override
  void initState() {
    super.initState();
    _mainButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _resetButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _skipButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _mainButtonController.dispose();
    _resetButtonController.dispose();
    _skipButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final pomodoroNotifier = ref.read(pomodoroProvider.notifier);
    final isAlarmPlaying = ref.watch(alarmStateProvider);

    // Calculate scale factor based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 320).clamp(
      1.0,
      2.2,
    ); // Base width 320dp, scale between 1.0x and 2.2x

    return Column(
      children: [
        // Main action buttons row - symmetrical design
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width *
                0.05, // Reduced from 0.08 to make buttons wider
          ),
          child: Row(
            children: [
              // Start/Pause Button
              Expanded(
                child: _buildMainActionButton(
                  pomodoroState,
                  pomodoroNotifier,
                  scaleFactor,
                ),
              ),
              SizedBox(width: 16 * scaleFactor),
              // Reset Button - same size as main button
              Expanded(child: _buildResetButton(pomodoroNotifier, scaleFactor)),
            ],
          ),
        ),
        SizedBox(height: 24 * scaleFactor),

        // Skip button - changes to Stop Alarm when alarm is playing
        _buildSkipButton(pomodoroNotifier, scaleFactor, isAlarmPlaying),
      ],
    );
  }

  Widget _buildMainActionButton(
    PomodoroState state,
    PomodoroNotifier notifier,
    double scaleFactor,
  ) {
    final isRunning = state.isRunning;
    final isPaused = state.isPaused;

    return AnimatedBuilder(
      animation: _mainButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_mainButtonController.value * 0.05),
          child: Container(
            height: 60 * scaleFactor,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * scaleFactor),
              gradient: LinearGradient(
                colors: isRunning
                    ? [const Color(0xFFFF8A65), const Color(0xFFFF7043)]
                    : [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRunning
                              ? const Color(0xFFFF7043)
                              : const Color(0xFF4CAF50))
                          .withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30 * scaleFactor),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _mainButtonController.forward().then((_) {
                    _mainButtonController.reverse();
                  });

                  if (isRunning) {
                    notifier.pauseTimer();
                  } else {
                    notifier.startTimer();
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24 * scaleFactor,
                      ),
                      SizedBox(
                        width: 8 * scaleFactor,
                      ), // Reduced spacing to move text closer to icon
                      Text(
                        isRunning ? 'Pause' : (isPaused ? 'Resume' : 'Start'),
                        style: TextStyle(
                          fontSize: 18 * scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5 * scaleFactor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResetButton(PomodoroNotifier notifier, double scaleFactor) {
    return AnimatedBuilder(
      animation: _resetButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_resetButtonController.value * 0.05),
          child: Container(
            height: 60 * scaleFactor, // Same height as main button
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * scaleFactor),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30 * scaleFactor),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _resetButtonController.forward().then((_) {
                    _resetButtonController.reverse();
                  });
                  notifier.resetTimer();
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 24 * scaleFactor, // Same icon size as main button
                      ),
                      SizedBox(
                        width: 12 * scaleFactor,
                      ), // Same spacing as main button
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize:
                              18 * scaleFactor, // Same font size as main button
                          fontWeight:
                              FontWeight.w700, // Same weight as main button
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing:
                              0.5 * scaleFactor, // Same letter spacing
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkipButton(
    PomodoroNotifier notifier,
    double scaleFactor,
    bool isAlarmPlaying,
  ) {
    return AnimatedBuilder(
      animation: _skipButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_skipButtonController.value * 0.03),
          child: Container(
            height: 48 * scaleFactor, // Smaller than main buttons
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24 * scaleFactor),
              border: Border.all(
                color: isAlarmPlaying
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.15),
                width: 1,
              ),
              gradient: isAlarmPlaying
                  ? LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.red.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24 * scaleFactor),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _skipButtonController.forward().then((_) {
                    _skipButtonController.reverse();
                  });

                  if (isAlarmPlaying) {
                    // Stop the alarm
                    AudioService.stopAlarmSound(
                      onStop: () {
                        ref.read(alarmStateProvider.notifier).state = false;
                      },
                    );
                  } else {
                    // Skip to next phase
                    notifier.skipToNextPhase();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scaleFactor,
                    vertical: 12 * scaleFactor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAlarmPlaying
                            ? Icons.stop_rounded
                            : Icons.skip_next_rounded,
                        color: isAlarmPlaying
                            ? Colors.red.withOpacity(0.9)
                            : Colors.white.withOpacity(0.7),
                        size: 20 * scaleFactor,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Text(
                        isAlarmPlaying ? 'Stop Alarm' : 'Skip Phase',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          color: isAlarmPlaying
                              ? Colors.red.withOpacity(0.9)
                              : Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
