import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../providers/security_provider.dart';

/// PIN ve/veya biyometrik doğrulama etkinse, uygulama her açıldığında
/// gösterilen kilit ekranı.
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final security = ref.read(securityProvider);
    if (!security.biometricEnabled || _checkingBiometric) return;
    setState(() => _checkingBiometric = true);
    final ok = await ref.read(securityProvider.notifier).authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _checkingBiometric = false);
    if (ok) widget.onUnlocked();
  }

  Future<void> _onDigit(String d) async {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == 4) {
      final ok = await ref.read(securityProvider.notifier).verifyPin(_entered);
      if (!mounted) return;
      if (ok) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'Yanlış PIN, tekrar dene';
          _entered = '';
        });
      }
    }
  }

  void _backspace() => setState(() => _entered = _entered.isEmpty ? '' : _entered.substring(0, _entered.length - 1));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final security = ref.watch(securityProvider);
    final subtitleColor = isDark ? AppColors.subtitleDark : AppColors.subtitleLight;
    final pinOnly = !security.pinSet; // Sadece biyometrik varsa PIN pedini gizleriz

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
                child: profile.photoPath == null
                    ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 32)
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Merhaba, ${profile.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                security.pinSet ? 'Devam etmek için PIN gir' : 'Devam etmek için doğrulama yap',
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
              const SizedBox(height: 32),
              if (security.pinSet) ...[
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
              ],
              const Spacer(),
              if (!pinOnly || security.pinSet) _buildKeypad(enabled: security.pinSet),
              if (security.biometricEnabled) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _checkingBiometric ? null : _tryBiometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Biyometrik ile giriş yap'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad({required bool enabled}) {
    if (!enabled) return const SizedBox.shrink();
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: keys.map((k) {
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
    );
  }
}
