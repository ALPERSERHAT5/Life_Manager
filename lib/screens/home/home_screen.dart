import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_complete_overlay.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final taskNotifier = ref.read(taskProvider.notifier);
    final todayTasks = taskNotifier.todayTasks;
    final completed = todayTasks.where((t) => t.isCompleted).length;
    final pending = todayTasks.length - completed;

    final txNotifier = ref.watch(transactionProvider.notifier);
    ref.watch(transactionProvider);
    final dailyIncome = txNotifier.todayAmount(income: true);
    final dailyExpense = txNotifier.todayAmount(income: false);

    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final dateStr = DateFormat('d MMMM EEEE', 'tr_TR').format(DateTime.now());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, Alper 👋',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hedeflerine devam et.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              StatCard(
                title: 'Bugünkü Görev',
                value: '${todayTasks.length}',
                icon: Icons.today_rounded,
                color: AppColors.primary,
                animationIndex: 0,
              ),
              StatCard(
                title: 'Tamamlanan',
                value: '$completed',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                animationIndex: 1,
              ),
              StatCard(
                title: 'Bekleyen',
                value: '$pending',
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                animationIndex: 2,
              ),
              StatCard(
                title: 'Günlük Gelir',
                value: currency.format(dailyIncome),
                icon: Icons.trending_up_rounded,
                color: AppColors.accent,
                animationIndex: 3,
              ),
              StatCard(
                title: 'Günlük Gider',
                value: currency.format(dailyExpense),
                icon: Icons.trending_down_rounded,
                color: AppColors.danger,
                animationIndex: 4,
              ),
              StatCard(
                title: 'Aylık Tasarruf',
                value: currency.format(txNotifier.balance),
                icon: Icons.savings_rounded,
                color: AppColors.secondary,
                animationIndex: 5,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bugünün Görevleri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (todayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Bugün için görevin yok 🎉',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.subtitleDark
                        : AppColors.subtitleLight,
                  ),
                ),
              ),
            )
          else
            ...todayTasks.map((task) => TaskCard(
                  task: task,
                  onToggle: () {
                    final willComplete = !task.isCompleted;
                    taskNotifier.toggleComplete(task);
                    if (willComplete) showTaskCompleteCelebration(context);
                  },
                  onDelete: () => taskNotifier.deleteTask(task),
                )),
        ],
      ),
    );
  }
}
