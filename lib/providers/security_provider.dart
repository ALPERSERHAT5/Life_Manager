import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPinHash = 'security_pin_hash';
const _kBiometric = 'security_biometric_enabled';

class SecurityState {
  final bool pinSet;
  final bool biometricEnabled;
  final bool loading;

  const SecurityState({this.pinSet = false, this.biometricEnabled = false, this.loading = true});

  /// Uygulama açılışında kilit ekranı gösterilmeli mi?
  bool get lockEnabled => pinSet || biometricEnabled;

  SecurityState copyWith({bool? pinSet, bool? biometricEnabled, bool? loading}) => SecurityState(
        pinSet: pinSet ?? this.pinSet,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        loading: loading ?? this.loading,
      );
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final _localAuth = LocalAuthentication();

  SecurityNotifier() : super(const SecurityState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SecurityState(
      pinSet: prefs.getString(_kPinHash) != null,
      biometricEnabled: prefs.getBool(_kBiometric) ?? false,
      loading: false,
    );
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinHash, _hash(pin));
    state = state.copyWith(pinSet: true);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPinHash);
    state = state.copyWith(pinSet: false);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPinHash);
    return saved != null && saved == _hash(pin);
  }

  Future<bool> deviceSupportsBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometric, value);
    state = state.copyWith(biometricEnabled: value);
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Life Manager\'a erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) => SecurityNotifier(),
);
