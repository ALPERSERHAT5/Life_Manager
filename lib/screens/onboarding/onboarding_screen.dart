import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/profile_provider.dart';

/// Uygulama ilk açıldığında gösterilen, kullanıcıdan isim ve (opsiyonel)
/// profil fotoğrafı alarak hesabı oluşturan karşılama ekranı.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  File? _photo;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;
    // Seçilen fotoğrafı kalıcı bir konuma kopyalıyoruz, aksi halde uygulama
    // yeniden başlatıldığında geçici dosya yolu geçersiz olabilir.
    final dir = await getApplicationDocumentsDirectory();
    final ext = picked.path.split('.').last;
    final savedPath = '${dir.path}/profile_photo.$ext';
    final saved = await File(picked.path).copy(savedPath);
    setState(() => _photo = saved);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Lütfen adını gir');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(profileProvider.notifier).completeOnboarding(name: name, photoPath: _photo?.path);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? AppColors.subtitleDark : AppColors.subtitleLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Life Manager\'a Hoş Geldin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Başlamadan önce seni tanıyalım',
                  style: TextStyle(fontSize: 13, color: subtitleColor)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? const Icon(Icons.person_rounded, size: 44, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Profil fotoğrafı ekle (opsiyonel)', style: TextStyle(fontSize: 12, color: subtitleColor)),
              const SizedBox(height: 28),
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Adın (örn. Alper)'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Başla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
