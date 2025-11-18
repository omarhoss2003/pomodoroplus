import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink(); // Hide in release mode
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Debug Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // First row of buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    'Test Notification 🧪',
                    'This is a test notification from PomodoroPlus!',
                    0,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Test Basic'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    'Focus Session Complete! ✅',
                    'Time for a short break. You deserve it!',
                    0,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer completion notification sent!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Test Timer End'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row for ongoing notification test
          ElevatedButton(
            onPressed: () async {
              await NotificationService.showOngoingNotification(
                title: '🎯 Focus Session in Progress',
                body: 'Stay focused and keep going!',
                timeLeft: '15:30',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ongoing notification sent!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Test Ongoing Notification'),
          ),
        ],
      ),
    );
  }
}
