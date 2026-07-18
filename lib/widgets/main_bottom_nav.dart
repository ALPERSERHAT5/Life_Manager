import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Ana Sayfa'),
    (icon: Icons.task_alt_rounded, label: 'Görevler'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Finans'),
    (icon: Icons.calendar_month_rounded, label: 'Takvim'),
    (icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final selected = index == currentIndex;
          final item = _items[index];
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: selected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      item.icon,
                      color: selected
                          ? AppColors.primary
                          : (isDark ? AppColors.subtitleDark : AppColors.subtitleLight),
                      size: 24,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
