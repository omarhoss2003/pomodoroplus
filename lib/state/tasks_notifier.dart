import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier();
});

final currentTaskProvider = StateProvider<Task?>((ref) {
  final tasks = ref.watch(tasksProvider);
  final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
  return incompleteTasks.isEmpty ? null : incompleteTasks.first;
});

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]) {
    _loadTasks();
  }

  static const String _storageKey = 'pomodoro_tasks';

  // Load tasks from shared preferences
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList(_storageKey) ?? [];

      final tasks = tasksJson
          .map((taskString) => Task.fromJson(jsonDecode(taskString)))
          .toList();

      // Sort tasks by creation date, incomplete first
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      state = tasks;

      if (kDebugMode) {
        print('📋 Loaded ${tasks.length} tasks from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading tasks: $e');
      }
      // Initialize with default tasks if loading fails
      _initializeDefaultTasks();
    }
  }

  // Save tasks to shared preferences
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = state.map((task) => jsonEncode(task.toJson())).toList();

      await prefs.setStringList(_storageKey, tasksJson);

      if (kDebugMode) {
        print('💾 Saved ${state.length} tasks to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving tasks: $e');
      }
    }
  }

  // Initialize with some default tasks
  void _initializeDefaultTasks() {
    final defaultTasks = [
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Complete project documentation',
        description: 'Write comprehensive documentation for the new feature',
        createdAt: DateTime.now(),
        estimatedPomodoros: 3,
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Review code changes',
        description: 'Review and approve pending pull requests',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
        estimatedPomodoros: 2,
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Plan next sprint',
        description:
            'Organize tasks and set priorities for the upcoming sprint',
        createdAt: DateTime.now().add(const Duration(seconds: 2)),
        estimatedPomodoros: 1,
      ),
    ];

    state = defaultTasks;
    _saveTasks();
  }

  // Add a new task
  Future<void> addTask(
    String title, {
    String description = '',
    int estimatedPomodoros = 1,
  }) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      estimatedPomodoros: estimatedPomodoros,
    );

    state = [...state, newTask];
    await _saveTasks();

    if (kDebugMode) {
      print('✅ Added new task: $title');
    }
  }

  // Update an existing task
  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    bool? isCompleted,
    int? estimatedPomodoros,
    int? completedPomodoros,
  }) async {
    state = state.map((task) {
      if (task.id == id) {
        return task.copyWith(
          title: title,
          description: description,
          isCompleted: isCompleted,
          estimatedPomodoros: estimatedPomodoros,
          completedPomodoros: completedPomodoros,
          completedAt: isCompleted == true ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();

    await _saveTasks();
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    final taskToDelete = state.firstWhere((task) => task.id == id);
    state = state.where((task) => task.id != id).toList();
    await _saveTasks();

    if (kDebugMode) {
      print('🗑️ Deleted task: ${taskToDelete.title}');
    }
  }

  // Mark current task as completed and move to next
  Future<void> completeCurrentTask() async {
    final incompleteTasks = state.where((task) => !task.isCompleted).toList();

    if (incompleteTasks.isNotEmpty) {
      final currentTask = incompleteTasks.first;
      await updateTask(currentTask.id, isCompleted: true);

      if (kDebugMode) {
        print('🎉 Completed task: ${currentTask.title}');
      }
    }
  }

  // Add pomodoro completion to current task
  Future<void> addPomodoroToCurrentTask() async {
    final incompleteTasks = state.where((task) => !task.isCompleted).toList();

    if (incompleteTasks.isNotEmpty) {
      final currentTask = incompleteTasks.first;
      final newCompletedPomodoros = currentTask.completedPomodoros + 1;

      // If task reaches estimated pomodoros, mark as completed
      final shouldComplete =
          newCompletedPomodoros >= currentTask.estimatedPomodoros;

      await updateTask(
        currentTask.id,
        completedPomodoros: newCompletedPomodoros,
        isCompleted: shouldComplete,
      );

      if (kDebugMode) {
        if (shouldComplete) {
          print('🎉 Task completed: ${currentTask.title}');
        } else {
          print(
            '⏱️ Pomodoro added to task: ${currentTask.title} ($newCompletedPomodoros/${currentTask.estimatedPomodoros})',
          );
        }
      }
    }
  }

  // Reorder tasks
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final tasks = List<Task>.from(state);
    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);
    state = tasks;
    await _saveTasks();
  }

  // Get tasks statistics
  Map<String, int> getStats() {
    final completedTasks = state.where((task) => task.isCompleted).length;
    final totalPomodoros = state.fold<int>(
      0,
      (sum, task) => sum + task.completedPomodoros,
    );
    final avgPomodorosPerTask = state.isNotEmpty
        ? (state.fold<int>(0, (sum, task) => sum + task.completedPomodoros) /
                  state.length)
              .round()
        : 0;

    return {
      'totalTasks': state.length,
      'completedTasks': completedTasks,
      'pendingTasks': state.length - completedTasks,
      'totalPomodoros': totalPomodoros,
      'avgPomodorosPerTask': avgPomodorosPerTask,
    };
  }
}
