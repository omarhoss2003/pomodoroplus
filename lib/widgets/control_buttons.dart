import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                child: _buildMainActionButton(pomodoroState, pomodoroNotifier),
              ),
              SizedBox(width: 16.w),
              // Reset Button - same size as main button
              Expanded(child: _buildResetButton(pomodoroNotifier)),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // Skip button - smaller
        _buildSkipButton(pomodoroNotifier),
      ],
    );
  }

  Widget _buildMainActionButton(
    PomodoroState state,
    PomodoroNotifier notifier,
  ) {
    final isRunning = state.isRunning;
    final isPaused = state.isPaused;

    return AnimatedBuilder(
      animation: _mainButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_mainButtonController.value * 0.05),
          child: Container(
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
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
                borderRadius: BorderRadius.circular(30.r),
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
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        isRunning ? 'Pause' : (isPaused ? 'Resume' : 'Start'),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5.w,
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

  Widget _buildResetButton(PomodoroNotifier notifier) {
    return AnimatedBuilder(
      animation: _resetButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_resetButtonController.value * 0.05),
          child: Container(
            height: 60.h, // Same height as main button
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30.r),
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
                        size: 24.sp, // Same icon size as main button
                      ),
                      SizedBox(width: 12.w), // Same spacing as main button
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 18.sp, // Same font size as main button
                          fontWeight:
                              FontWeight.w700, // Same weight as main button
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5.w, // Same letter spacing
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

  Widget _buildSkipButton(PomodoroNotifier notifier) {
    return AnimatedBuilder(
      animation: _skipButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_skipButtonController.value * 0.03),
          child: Container(
            height: 48.h, // Smaller than main buttons
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24.r),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _skipButtonController.forward().then((_) {
                    _skipButtonController.reverse();
                  });

                  // Check if alarm is playing and stop it
                  if (AudioService.isAlarmPlaying()) {
                    AudioService.stopAlarmSound();
                  } else {
                    notifier.skipToNextPhase();
                  }
                },
                onLongPress: () {
                  // Debug: Test alarm sound on long press
                  HapticFeedback.heavyImpact();
                  AudioService.testAlarm();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AudioService.isAlarmPlaying()
                            ? Icons.volume_off_rounded
                            : Icons.skip_next_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        AudioService.isAlarmPlaying()
                            ? 'Stop Alarm'
                            : 'Skip Phase',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3.w,
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
