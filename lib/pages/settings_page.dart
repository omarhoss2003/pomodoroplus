import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../state/settings_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Timer Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await settingsNotifier.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Settings reset to defaults',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF66BB6A),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize your Pomodoro timer durations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 30.h), // Reduced from 40.h
                // Work Timer Setting
                _buildTimerSetting(
                  title: 'Work Timer',
                  description: 'Focus session duration',
                  value: settings.workMinutes,
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFF66BB6A),
                  onChanged: settingsNotifier.updateWorkMinutes,
                  minValue: 1,
                  maxValue: 90,
                ),

                SizedBox(height: 24.h), // Reduced from 32.h
                // Short Break Setting
                _buildTimerSetting(
                  title: 'Short Break',
                  description: 'Quick break duration',
                  value: settings.shortBreakMinutes,
                  icon: Icons.coffee_outlined,
                  color: const Color(0xFF42A5F5),
                  onChanged: settingsNotifier.updateShortBreakMinutes,
                  minValue: 1,
                  maxValue: 30,
                ),

                SizedBox(height: 24.h), // Reduced from 32.h
                // Long Break Setting
                _buildTimerSetting(
                  title: 'Long Break',
                  description: 'Extended break duration',
                  value: settings.longBreakMinutes,
                  icon: Icons.hotel_outlined,
                  color: const Color(0xFFFF8A65),
                  onChanged: settingsNotifier.updateLongBreakMinutes,
                  minValue: 1,
                  maxValue: 60,
                ),

                SizedBox(height: 30.h), // Reduced from 40.h

                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: const Color(0xFF66BB6A),
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Pomodoro Technique',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '• Work for focused periods, then take breaks\n'
                        '• After 4 work sessions, take a long break\n'
                        '• Default: 25min work, 5min short, 15min long break\n'
                        '• Customize these durations to fit your needs',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding for scroll view
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSetting({
    required String title,
    required String description,
    required int value,
    required IconData icon,
    required Color color,
    required void Function(int) onChanged,
    required int minValue,
    required int maxValue,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              // Decrease button
              _buildCounterButton(
                icon: Icons.remove_rounded,
                onTap: value > minValue
                    ? () {
                        HapticFeedback.lightImpact();
                        onChanged(value - 1);
                      }
                    : null,
                color: color,
              ),
              SizedBox(width: 16.w),

              // Value display
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$value min',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // Increase button
              _buildCounterButton(
                icon: Icons.add_rounded,
                onTap: value < maxValue
                    ? () {
                        HapticFeedback.lightImpact();
                        onChanged(value + 1);
                      }
                    : null,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isEnabled
                ? color.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: 1.w,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? color : Colors.white.withOpacity(0.3),
          size: 24.sp,
        ),
      ),
    );
  }
}
