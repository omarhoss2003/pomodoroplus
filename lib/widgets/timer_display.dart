import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../state/pomodoro_notifier.dart';
import '../models/pomodoro_state.dart';

class TimerDisplay extends ConsumerStatefulWidget {
  const TimerDisplay({super.key});

  @override
  ConsumerState<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends ConsumerState<TimerDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);

    // Trigger scale animation on state changes
    if (pomodoroState.isRunning != _wasRunning) {
      _scaleController.forward().then((_) => _scaleController.reverse());
      _wasRunning = pomodoroState.isRunning;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase indicator with glow effect
              _buildPhaseIndicator(pomodoroState),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Main circular timer with enhanced design
              _buildCircularTimer(pomodoroState),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Stats row
              _buildStatsRow(pomodoroState),
            ],
          ),
        );
      },
    );
  }

  bool _wasRunning = false;

  Widget _buildPhaseIndicator(PomodoroState state) {
    final phaseData = _getPhaseData(state.currentPhase);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phaseData.color.withOpacity(0.2),
            phaseData.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: phaseData.color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: phaseData.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: phaseData.color,
              shape: BoxShape.circle,
            ),
            child: Icon(phaseData.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            state.phaseDisplayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: phaseData.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(PomodoroState state) {
    final phaseData = _getPhaseData(state.currentPhase);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Make timer responsive to screen size
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final smallerDimension = screenWidth < screenHeight
            ? screenWidth
            : screenHeight;

        // Scale radius based on screen size, with reasonable min/max bounds
        final radius = (smallerDimension * 0.25).clamp(80.0, 140.0);
        final lineWidth = (radius * 0.08).clamp(6.0, 12.0);

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: phaseData.color.withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 40 * _pulseAnimation.value,
                spreadRadius: 5 * _pulseAnimation.value,
              ),
            ],
          ),
          child: CircularPercentIndicator(
            radius: radius,
            lineWidth: lineWidth,
            animation: true,
            // animateFromLastPercent prevents the progress ring from
            // restarting from 0 on each rebuild (tick). This keeps a
            // smooth, continuous animation as the timer updates every second.
            animateFromLastPercent: true,
            animationDuration: 500,
            percent: state.progress,
            center: _buildTimerCenter(state, phaseData),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: phaseData.color,
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        );
      },
    );
  }

  Widget _buildTimerCenter(PomodoroState state, PhaseData phaseData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            // Make text size responsive to screen
            final screenWidth = MediaQuery.of(context).size.width;
            final fontSize = (screenWidth * 0.13).clamp(32.0, 52.0);

            return Transform.scale(
              scale: value,
              child: Text(
                state.formattedTime,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -2,
                  shadows: [
                    Shadow(
                      color: phaseData.color.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (state.isPaused) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.orange,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(PomodoroState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Cycles',
          value: '${state.completedCycles}',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: '${state.completedCycles > 0 ? state.completedCycles : 0}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.timer_outlined,
          label: 'Phase',
          value: '${(state.completedCycles % 4) + 1}/4',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  PhaseData _getPhaseData(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return PhaseData(
          color: const Color(0xFFFF6B6B),
          icon: Icons.work_outline_rounded,
        );
      case PomodoroPhase.shortBreak:
        return PhaseData(
          color: const Color(0xFF51CF66),
          icon: Icons.coffee_outlined,
        );
      case PomodoroPhase.longBreak:
        return PhaseData(
          color: const Color(0xFF339AF0),
          icon: Icons.spa_outlined,
        );
    }
  }
}

class PhaseData {
  final Color color;
  final IconData icon;

  PhaseData({required this.color, required this.icon});
}
