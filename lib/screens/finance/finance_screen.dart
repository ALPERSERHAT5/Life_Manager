import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_sheet.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _period = 'Haftalık';

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final notifier = ref.watch(transactionProvider.notifier);
    final transactions = ref.watch(transactionProvider)..sort((a, b) => b.date.compareTo(a.date));
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final byCategory = notifier.expensesByCategory();

    final pieColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.warning,
      AppColors.danger,
      AppColors.success,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text('Finans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toplam Bakiye', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(currency.format(notifier.balance),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat('Gelir', currency.format(notifier.totalIncome),
                            Icons.arrow_downward_rounded, AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStat('Gider', currency.format(notifier.totalExpense),
                            Icons.arrow_upward_rounded, AppColors.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gelir & Gider',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDark : AppColors.textLight)),
                _periodSelector(isDark),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildBarChart(notifier.chartData(_period), isDark),
            ),
            const SizedBox(height: 24),
            if (byCategory.isNotEmpty) ...[
              Text('Kategoriye Göre Gider',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          sections: byCategory.entries.toList().asMap().entries.map((e) {
                            final color = pieColors[e.key % pieColors.length];
                            return PieChartSectionData(
                              value: e.value.value,
                              color: color,
                              title: '',
                              radius: 20,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: byCategory.entries.toList().asMap().entries.map((e) {
                          final color = pieColors[e.key % pieColors.length];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(e.value.key,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text(currency.format(e.value.value),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text('Son İşlemler',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight)),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text('Henüz işlem yok',
                      style: TextStyle(
                          color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
                ),
              )
            else
              ...transactions.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (t.isIncome ? AppColors.success : AppColors.danger)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            t.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: t.isIncome ? AppColors.success : AppColors.danger,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(DateFormat('d MMM, HH:mm', 'tr_TR').format(t.date),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
                            ],
                          ),
                        ),
                        Text(
                          '${t.isIncome ? '+' : '-'}${currency.format(t.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.isIncome ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _periodSelector(bool isDark) {
    const periods = ['Haftalık', 'Aylık', 'Yıllık'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: periods.map((p) {
          final selected = p == _period;
          return GestureDetector(
            onTap: () => setState(() => _period = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? AppColors.subtitleDark : AppColors.subtitleLight),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(List<ChartPoint> data, bool isDark) {
    if (data.every((d) => d.income == 0 && d.expense == 0)) {
      return Center(
        child: Text('Bu dönem için veri yok',
            style: TextStyle(color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
      );
    }
    final maxVal = data
        .map((d) => d.income > d.expense ? d.income : d.expense)
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 100.0 : maxVal * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data[i].label,
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: true),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.income,
                color: AppColors.success,
                width: 7,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: e.value.expense,
                color: AppColors.danger,
                width: 7,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            barsSpace: 4,
          );
        }).toList(),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
