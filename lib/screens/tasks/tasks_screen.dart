import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_complete_overlay.dart';
import 'add_task_sheet.dart';

enum _Filter { hepsi, bekleyen, tamamlanan }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Filter _filter = _Filter.hepsi;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    final filtered = switch (_filter) {
      _Filter.hepsi => tasks,
      _Filter.bekleyen => notifier.pendingTasks,
      _Filter.tamamlanan => notifier.completedTasks,
    }..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Text('Görevler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _filterChip('Hepsi', _Filter.hepsi),
                  const SizedBox(width: 8),
                  _filterChip('Bekleyen', _Filter.bekleyen),
                  const SizedBox(width: 8),
                  _filterChip('Tamamlanan', _Filter.tamamlanan),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Burada henüz görev yok',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.subtitleDark
                              : AppColors.subtitleLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return TaskCard(
                          task: task,
                          onToggle: () {
                            final willComplete = !task.isCompleted;
                            notifier.toggleComplete(task);
                            if (willComplete) showTaskCompleteCelebration(context);
                          },
                          onDelete: () => notifier.deleteTask(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _Filter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.primary : Colors.transparent),
      ),
    );
  }
}
