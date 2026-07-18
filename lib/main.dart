import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/main_shell.dart';
import 'providers/profile_provider.dart';
import 'providers/security_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/security/lock_screen.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await NotificationService().init();
  await initializeDateFormatting('tr_TR', null);

  runApp(const ProviderScope(child: LifeManagerApp()));
}

class LifeManagerApp extends ConsumerWidget {
  const LifeManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Life Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AppGate(),
    );
  }
}

/// Uygulama açılışındaki akışı yönetir:
/// 1) Hesap oluşturulmadıysa -> Onboarding (isim + profil fotoğrafı)
/// 2) PIN/biyometrik kilit etkinse ve henüz açılmadıysa -> LockScreen
/// 3) Aksi halde -> Ana uygulama (MainShell)
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final security = ref.watch(securityProvider);

    if (profile.loading || security.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!profile.onboarded) {
      return const OnboardingScreen();
    }

    if (security.lockEnabled && !_unlocked) {
      return LockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }

    return const MainShell();
  }
}
