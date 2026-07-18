import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';
import '../security/pin_setup_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = picked.path.split('.').last;
    final savedPath = '${dir.path}/profile_photo.$ext';
    final saved = await File(picked.path).copy(savedPath);
    await ref.read(profileProvider.notifier).updatePhoto(saved.path);
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İsmini Düzenle'),
        content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await ref.read(profileProvider.notifier).updateName(newName);
    }
  }

  Future<void> _handlePinTile(BuildContext context, WidgetRef ref, bool pinSet) async {
    if (!pinSet) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('PIN\'i Değiştir'),
              onTap: () => Navigator.pop(ctx, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open_rounded, color: AppColors.danger),
              title: const Text('PIN Korumasını Kaldır', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == 'change') {
      if (context.mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
      }
    } else if (action == 'remove') {
      await ref.read(securityProvider.notifier).removePin();
    }
  }

  Future<void> _handleBiometricToggle(BuildContext context, WidgetRef ref, bool value) async {
    final notifier = ref.read(securityProvider.notifier);
    if (value) {
      final supported = await notifier.deviceSupportsBiometrics();
      if (!supported) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu cihazda biyometrik doğrulama bulunamadı')),
          );
        }
        return;
      }
      final ok = await notifier.authenticateWithBiometrics();
      if (!ok) return;
    }
    await notifier.setBiometricEnabled(value);
  }

  Future<void> _handleBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Yedek hazırlanıyor...')));
    try {
      await BackupService.exportAndShare();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Yedekleme başarısız: $e')));
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedekten Geri Yükle'),
        content: const Text(
            'Seçtiğin yedek dosyasındaki veriler, uygulamadaki mevcut görev, işlem ve etkinliklerin yerini alacak. Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devam Et')),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final restored = await BackupService.pickAndRestore();
      if (restored) {
        messenger.showSnackBar(const SnackBar(content: Text('Veriler başarıyla geri yüklendi')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Geri yükleme başarısız: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final taskNotifier = ref.watch(taskProvider.notifier);
    ref.watch(taskProvider);
    final completed = taskNotifier.completedTasks.length;
    final total = ref.watch(taskProvider).length;
    final successRate = total == 0 ? 0 : ((completed / total) * 100).round();

    final profile = ref.watch(profileProvider);
    final security = ref.watch(securityProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _changePhoto(context, ref),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white24,
                        backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
                        child: profile.photoPath == null
                            ? const Icon(Icons.person_rounded, color: Colors.white, size: 32)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(profile.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                            onPressed: () => _editName(context, ref, profile.name),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Life Manager kullanıcısı',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statBox(context, 'Başarı Oranı', '%$successRate', AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(context, 'Tamamlanan', '$completed', AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _statBox(context, 'Kaçırılan', '${taskNotifier.missedTasks.length}',
                      AppColors.danger)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox(context, 'Haftalık Verim', '%${taskNotifier.weeklyProductivity}',
                      AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statBox(context, 'Seri 🔥', '${taskNotifier.streak} gün', AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Görünüm'),
          _settingsTile(
            context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Karanlık Mod',
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.primary,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setDark(v),
            ),
          ),
          _settingsTile(context, icon: Icons.language_rounded, title: 'Dil', subtitle: 'Türkçe'),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Bildirimler & Güvenlik'),
          _settingsTile(context, icon: Icons.notifications_active_rounded, title: 'Bildirim Ayarları'),
          _settingsTile(
            context,
            icon: Icons.fingerprint_rounded,
            title: 'Biyometrik Giriş',
            subtitle: security.biometricEnabled ? 'Açık' : 'Kapalı',
            trailing: Switch(
              value: security.biometricEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => _handleBiometricToggle(context, ref, v),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.pin_rounded,
            title: 'PIN Koruması',
            subtitle: security.pinSet ? 'Açık' : 'Kapalı',
            onTap: () => _handlePinTile(context, ref, security.pinSet),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Veri'),
          _settingsTile(
            context,
            icon: Icons.backup_rounded,
            title: 'Yedekleme',
            subtitle: 'Tüm verilerini JSON olarak yedekle',
            onTap: () => _handleBackup(context),
          ),
          _settingsTile(
            context,
            icon: Icons.ios_share_rounded,
            title: 'Verileri Dışa Aktar',
            subtitle: 'Paylaş / cihaza kaydet',
            onTap: () => _handleBackup(context),
          ),
          _settingsTile(
            context,
            icon: Icons.restore_rounded,
            title: 'Yedekten Geri Yükle',
            subtitle: 'Bir yedek dosyasından verileri geri getir',
            onTap: () => _handleRestore(context),
          ),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
    );
  }

  Widget _settingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      ),
    );
  }
}
