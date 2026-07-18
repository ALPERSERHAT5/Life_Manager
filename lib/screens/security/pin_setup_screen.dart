import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/security_provider.dart';

/// Yeni bir 4 haneli PIN belirlemek (veya değiştirmek) için kullanılan ekran.
/// PIN iki kez girdirilerek doğrulanır. Başarıyla kaydedilirse `true` ile
/// pop edilir.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _first = '';
  String _entered = '';
  bool _confirmStep = false;
  String? _error;

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == 4) _handleComplete();
  }

  void _backspace() => setState(() => _entered = _entered.isEmpty ? '' : _entered.substring(0, _entered.length - 1));

  Future<void> _handleComplete() async {
    if (!_confirmStep) {
      setState(() {
        _first = _entered;
        _entered = '';
        _confirmStep = true;
      });
      return;
    }
    if (_entered == _first) {
      await ref.read(securityProvider.notifier).setPin(_entered);
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'PIN\'ler eşleşmedi, tekrar deneyin';
        _entered = '';
        _first = '';
        _confirmStep = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('PIN Belirle')),
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                _confirmStep ? 'PIN\'i onaylayın' : 'Yeni bir 4 haneli PIN girin',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _entered.length ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              const Spacer(),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'].map((k) {
                  if (k.isEmpty) return const SizedBox.shrink();
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => k == '⌫' ? _backspace() : _onDigit(k),
                    child: Center(
                      child: k == '⌫'
                          ? const Icon(Icons.backspace_outlined)
                          : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
