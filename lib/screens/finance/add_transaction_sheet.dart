import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/transaction_provider.dart';

const _expenseCategories = ['Market', 'Kira', 'Fatura', 'Yakıt', 'Yemek', 'Diğer'];
const _incomeCategories = ['Maaş', 'Freelance', 'Yatırım', 'Diğer'];

Future<void> showAddTransactionSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet();

  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isIncome = false;
  String _category = 'Market';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Yeni İşlem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _typeButton('Gider', !_isIncome, AppColors.danger, () {
                    setState(() {
                      _isIncome = false;
                      _category = _expenseCategories.first;
                    });
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeButton('Gelir', _isIncome, AppColors.success, () {
                    setState(() {
                      _isIncome = true;
                      _category = _incomeCategories.first;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Tutar (₺)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(hintText: 'Açıklama (opsiyonel)'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: selected ? AppColors.primary : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return;
                  ref.read(transactionProvider.notifier).addTransaction(
                        amount: amount,
                        description: _descCtrl.text.trim(),
                        date: DateTime.now(),
                        category: _category,
                        isIncome: _isIncome,
                      );
                  Navigator.pop(context);
                },
                child: const Text('İşlemi Ekle',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? color : null, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
