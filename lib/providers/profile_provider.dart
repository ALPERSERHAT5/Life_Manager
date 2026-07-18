import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kName = 'profile_name';
const _kPhoto = 'profile_photo_path';
const _kOnboarded = 'onboarding_complete';

/// Kullanıcının profil bilgilerini (isim, fotoğraf) ve ilk açılış (onboarding)
/// durumunu tutar.
class ProfileState {
  final String name;
  final String? photoPath;
  final bool onboarded;
  final bool loading;

  const ProfileState({
    this.name = 'Kullanıcı',
    this.photoPath,
    this.onboarded = false,
    this.loading = true,
  });

  ProfileState copyWith({
    String? name,
    String? photoPath,
    bool clearPhoto = false,
    bool? onboarded,
    bool? loading,
  }) {
    return ProfileState(
      name: name ?? this.name,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      onboarded: onboarded ?? this.onboarded,
      loading: loading ?? this.loading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ProfileState(
      name: prefs.getString(_kName) ?? 'Kullanıcı',
      photoPath: prefs.getString(_kPhoto),
      onboarded: prefs.getBool(_kOnboarded) ?? false,
      loading: false,
    );
  }

  /// Onboarding ekranında girilen isim/fotoğrafla hesabı oluşturur.
  Future<void> completeOnboarding({required String name, String? photoPath}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name);
    if (photoPath != null) await prefs.setString(_kPhoto, photoPath);
    await prefs.setBool(_kOnboarded, true);
    state = state.copyWith(name: name, photoPath: photoPath, onboarded: true);
  }

  Future<void> updateName(String name) async {
    if (name.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name.trim());
    state = state.copyWith(name: name.trim());
  }

  Future<void> updatePhoto(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kPhoto);
    } else {
      await prefs.setString(_kPhoto, path);
    }
    state = state.copyWith(photoPath: path, clearPhoto: path == null);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);
