import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Görev ve randevu bildirimlerini yönetir:
/// - 15 dakika önce hatırlatma
/// - Tam saatinde alarm
/// - Tamamlanmazsa 30 dk sonra tekrar uyarı
/// - İstenirse 1 saat sonra tekrar hatırlatma
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'life_manager_channel',
          'Life Manager Bildirimleri',
          channelDescription: 'Görev ve randevu hatırlatmaları',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Bir görev/etkinlik için tüm bildirim zincirini planlar.
  /// [id] her görev için benzersiz bir taban kimlik olmalı (ör. görevin hashCode'u).
  Future<void> scheduleTaskReminders({
    required int id,
    required String title,
    required DateTime scheduledDate,
    bool repeatIfMissed = true,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime.from(scheduledDate, tz.local);
    if (target.isBefore(now)) return;

    // 15 dakika önce hatırlatma
    final before15 = target.subtract(const Duration(minutes: 15));
    if (before15.isAfter(now)) {
      await _plugin.zonedSchedule(
        id * 10 + 1,
        '⏰ Yaklaşan görev',
        '"$title" 15 dakika sonra başlıyor.',
        before15,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Tam saatinde alarm
    await _plugin.zonedSchedule(
      id * 10 + 2,
      '🔔 Görev zamanı!',
      '"$title" şimdi başlıyor.',
      target,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    if (repeatIfMissed) {
      // 30 dakika sonra tekrar uyarı
      await _plugin.zonedSchedule(
        id * 10 + 3,
        '⚠️ Görev tamamlanmadı',
        '"$title" hâlâ bekliyor. Unutma!',
        target.add(const Duration(minutes: 30)),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // 1 saat sonra son hatırlatma
      await _plugin.zonedSchedule(
        id * 10 + 4,
        '🔁 Son hatırlatma',
        '"$title" için son bir hatırlatma.',
        target.add(const Duration(hours: 1)),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Görev tamamlandığında bekleyen bildirimleri iptal eder.
  Future<void> cancelTaskReminders(int id) async {
    await _plugin.cancel(id * 10 + 1);
    await _plugin.cancel(id * 10 + 2);
    await _plugin.cancel(id * 10 + 3);
    await _plugin.cancel(id * 10 + 4);
  }

  Future<void> showInstantNotification(String title, String body) async {
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, _details);
  }
}
