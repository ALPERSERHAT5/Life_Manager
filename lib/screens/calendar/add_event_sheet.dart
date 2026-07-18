import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/event_provider.dart';

const _types = ['Randevu', 'Toplantı', 'Ders', 'Not', 'Etkinlik'];

Future<void> showAddEventSheet(BuildContext context, WidgetRef ref, DateTime selectedDay) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddEventSheet(selectedDay: selectedDay),
  );
}

class _AddEventSheet extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  const _AddEventSheet({required this.selectedDay});

  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  String _type = 'Randevu';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Yeni Etkinlik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Başlık')),
              const SizedBox(height: 12),
              TextField(controller: _locationCtrl, decoration: const InputDecoration(hintText: 'Konum (opsiyonel)')),
              const SizedBox(height: 12),
              TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Not (opsiyonel)')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 16),
                label: Text(_time.format(context)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final selected = t == _type;
                  return ChoiceChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
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
                    if (_titleCtrl.text.trim().isEmpty) return;
                    ref.read(eventProvider.notifier).addEvent(
                          title: _titleCtrl.text.trim(),
                          type: _type,
                          date: widget.selectedDay,
                          time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                          location: _locationCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
