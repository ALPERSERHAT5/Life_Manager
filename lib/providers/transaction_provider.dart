import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super(HiveService.transactions.values.toList());

  void _refresh() => state = HiveService.transactions.values.toList();

  Future<void> addTransaction({
    required double amount,
    String description = '',
    required DateTime date,
    required String category,
    required bool isIncome,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      date: date,
      category: category,
      isIncome: isIncome,
    );
    await HiveService.transactions.put(tx.id, tx);
    _refresh();
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    await tx.delete();
    _refresh();
  }

  double get totalIncome => state.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
  double get totalExpense => state.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
  double get balance => totalIncome - totalExpense;

  double todayAmount({required bool income}) {
    final now = DateTime.now();
    return state
        .where((t) =>
            t.isIncome == income &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> expensesByCategory() {
    final map = <String, double>{};
    for (final t in state.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  /// Son [days] gün için günlük net (gelir-gider) listesi.
  List<double> dailyNet(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final dayTx = state.where(
        (t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day,
      );
      final income = dayTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final expense = dayTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
      return income - expense;
    });
  }

  /// Grafik ekranı için dönem bazlı gelir/gider verisi.
  /// period: 'Haftalık' (son 7 gün), 'Aylık' (son 6 ay), 'Yıllık' (son 5 yıl)
  List<ChartPoint> chartData(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Aylık':
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i));
          final tx = state.where((t) => t.date.year == month.year && t.date.month == month.month);
          return ChartPoint(
            label: _monthShort(month.month),
            income: tx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
            expense: tx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
          );
        });
      case 'Yıllık':
        return List.generate(5, (i) {
          final year = now.year - (4 - i);
          final tx = state.where((t) => t.date.year == year);
          return ChartPoint(
            label: '$year',
            income: tx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
            expense: tx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
          );
        });
      case 'Haftalık':
      default:
        const dayLabels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final tx = state.where(
              (t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day);
          return ChartPoint(
            label: dayLabels[(day.weekday - 1) % 7],
            income: tx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
            expense: tx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
          );
        });
    }
  }

  String _monthShort(int month) {
    const names = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return names[month - 1];
  }
}

/// Grafiklerde kullanılan tek bir dönem noktası (gün/ay/yıl).
class ChartPoint {
  final String label;
  final double income;
  final double expense;
  const ChartPoint({required this.label, required this.income, required this.expense});
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) => TransactionNotifier(),
);
