import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

enum SoundOption { defaultSound, alarm, ringtone, silent }

extension SoundOptionX on SoundOption {
  String get label {
    switch (this) {
      case SoundOption.defaultSound:
        return 'Default';
      case SoundOption.alarm:
        return 'Alarm';
      case SoundOption.ringtone:
        return 'Ringtone';
      case SoundOption.silent:
        return 'Silent';
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    // Phone ke current UTC offset se matching timezone dhoondo (plugin ki zaroorat nahi)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    tz.Location? match;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.timeZone(nowMs).offset == offsetMs) {
        match = loc;
        break;
      }
    }
    tz.setLocalLocation(match ?? tz.UTC);
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
  }

  // One channel per sound option (Android channel sounds can't change later).
  static AndroidNotificationDetails _android(SoundOption s) {
    AndroidNotificationSound? sound;
    if (s == SoundOption.alarm) {
      sound = const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert');
    } else if (s == SoundOption.ringtone) {
      sound =
          const UriAndroidNotificationSound('content://settings/system/ringtone');
    }
    return AndroidNotificationDetails(
      'tasks_${s.name}',
      'Task reminders (${s.label})',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: s != SoundOption.silent,
      sound: sound,
    );
  }

  static NotificationDetails _details(SoundOption s) =>
      NotificationDetails(android: _android(s));

  static tz.TZDateTime _next(DateTime t, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    while (d.isBefore(now) || (weekday != null && d.weekday != weekday)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static Future<void> cancel(int taskId) async {
    for (var i = 0; i <= 7; i++) {
      await _plugin.cancel(taskId * 10 + i);
    }
  }

  static Future<void> _zoned(int id, Task t, tz.TZDateTime when, SoundOption s,
      {DateTimeComponents? match}) {
    return _plugin.zonedSchedule(
      id,
      t.title,
      t.description.isEmpty ? 'Your task is due now' : t.description,
      when,
      _details(s),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  }

  static Future<void> schedule(Task t, SoundOption s) async {
    if (t.id == null) return;
    await cancel(t.id!);
    final base = t.id! * 10;
    switch (t.repeatType) {
      case 'daily':
        await _zoned(base, t, _next(t.dueDate), s,
            match: DateTimeComponents.time);
        break;
      case 'weekly':
        for (final d in t.repeatDays) {
          await _zoned(base + d, t, _next(t.dueDate, weekday: d), s,
              match: DateTimeComponents.dayOfWeekAndTime);
        }
        break;
      default:
        if (t.isCompleted) return;
        final when = tz.TZDateTime.from(t.dueDate, tz.local);
        if (when.isAfter(tz.TZDateTime.now(tz.local))) {
          await _zoned(base, t, when, s);
        }
    }
  }

  static Future<void> rescheduleAll(List<Task> tasks, SoundOption s) async {
    for (final t in tasks) {
      await schedule(t, s);
    }
  }

  static Future<void> showTest(SoundOption s) => _plugin.show(
      999999, 'Test notification', 'Notifications are working!', _details(s));
}
