import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  TaskNotifier() : super(HiveService.tasks.values.toList());

  void _refresh() => state = HiveService.tasks.values.toList();

  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime date,
    required String time,
    String priority = 'Orta',
    String category = 'Diğer',
    String repeat = 'Yok',
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      date: date,
      time: time,
      priority: priority,
      category: category,
      repeat: repeat,
    );
    await HiveService.tasks.put(task.id, task);
    _refresh();

    final scheduled = _combineDateAndTime(date, time);
    if (scheduled != null) {
      await NotificationService().scheduleTaskReminders(
        id: task.id.hashCode & 0x7FFFFFFF,
        title: title,
        scheduledDate: scheduled,
      );
    }
  }

  Future<void> toggleComplete(TaskModel task) async {
    task.isCompleted = !task.isCompleted;
    await task.save();
    if (task.isCompleted) {
      await NotificationService().cancelTaskReminders(task.id.hashCode & 0x7FFFFFFF);
    }
    _refresh();
  }

  Future<void> deleteTask(TaskModel task) async {
    await NotificationService().cancelTaskReminders(task.id.hashCode & 0x7FFFFFFF);
    await task.delete();
    _refresh();
  }

  DateTime? _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return state
        .where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<TaskModel> get completedTasks => state.where((t) => t.isCompleted).toList();
  List<TaskModel> get pendingTasks => state.where((t) => !t.isCompleted).toList();

  /// Zamanı geçmiş ama hâlâ tamamlanmamış görevler.
  List<TaskModel> get missedTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return state.where((t) => !t.isCompleted && t.date.isBefore(todayStart)).toList();
  }

  /// Son 7 gündeki tamamlanma yüzdesi.
  int get weeklyProductivity {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekTasks = state.where((t) => t.date.isAfter(weekAgo) && !t.date.isAfter(now)).toList();
    if (weekTasks.isEmpty) return 0;
    final done = weekTasks.where((t) => t.isCompleted).length;
    return ((done / weekTasks.length) * 100).round();
  }

  /// Bugünden geriye doğru, görevi olan ve hepsi tamamlanmış ardışık gün sayısı.
  int get streak {
    int streakCount = 0;
    var day = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final dayTasks = state.where(
        (t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day,
      );
      if (dayTasks.isEmpty) {
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      final allDone = dayTasks.every((t) => t.isCompleted);
      if (!allDone) break;
      streakCount++;
      day = day.subtract(const Duration(days: 1));
    }
    return streakCount;
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>(
  (ref) => TaskNotifier(),
);

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  ref.watch(taskProvider);
  return ref.read(taskProvider.notifier).todayTasks;
});
