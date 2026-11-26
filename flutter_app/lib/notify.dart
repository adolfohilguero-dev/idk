import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'data.dart';

/// Avisos locals programats: el dia abans (9:00) i el mateix dia (8:00)
/// de cada avaluable. Funcionen amb l'app tancada.
class Notify {
  static final FlutterLocalNotificationsPlugin _p =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _prefKey = 'smx_notif';

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _p.initialize(init);
      _ready = true;
      if (await isEnabled()) await scheduleAll();
    } catch (_) {
      _ready = false;
    }
  }

  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefKey) ?? false;
  }

  /// Activa o desactiva els avisos. Retorna l'estat final.
  static Future<bool> setEnabled(bool on) async {
    final p = await SharedPreferences.getInstance();
    if (!_ready) return false;
    if (on) {
      final android = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) {
        await p.setBool(_prefKey, false);
        return false;
      }
      await p.setBool(_prefKey, true);
      await scheduleAll();
      await _p.show(
        0,
        '✅ Avisos activats',
        "T'avisaré el dia abans i el mateix dia de cada avaluable.",
        _details,
      );
      return true;
    }
    await p.setBool(_prefKey, false);
    await _p.cancelAll();
    return false;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'avaluables',
      'Avaluables',
      channelDescription: 'Avisos de proves i activitats avaluables',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> scheduleAll() async {
    if (!_ready) return;
    await _p.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var id = 100;
    for (final e in Data.events) {
      if (!e.exam) continue;
      final dayBefore =
          tz.TZDateTime(tz.local, e.d.year, e.d.month, e.d.day - 1, 9);
      final sameDayAt =
          tz.TZDateTime(tz.local, e.d.year, e.d.month, e.d.day, 8);
      final body = '${e.modName.split(' · ').first} · ${e.o.isEmpty ? e.s : e.o}';
      if (dayBefore.isAfter(now)) {
        await _schedule(id++, '🧪 Demà: ${e.s}', body, dayBefore);
      }
      if (sameDayAt.isAfter(now)) {
        await _schedule(id++, '🧪 ${e.w ? 'Aquesta setmana' : 'Avui'}: ${e.s}',
            body, sameDayAt);
      }
    }
  }

  static Future<void> _schedule(
      int id, String title, String body, tz.TZDateTime when) async {
    try {
      await _p.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}
