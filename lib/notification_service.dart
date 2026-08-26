import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'food.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'dlc_reminders';
  static const _channelName = 'Rappels DLC';
  static const _reminderOffsets = [7, 3, 1, 0];

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> syncFoodReminders(Food food) async {
    await cancelFoodReminders(food.id);

    if (food.status != FoodStatus.active) return;

    final now = tz.TZDateTime.now(tz.local);

    for (final daysBefore in _reminderOffsets) {
      final targetDay = DateTime(
        food.expirationDate.year,
        food.expirationDate.month,
        food.expirationDate.day,
      ).subtract(Duration(days: daysBefore));

      final scheduled = tz.TZDateTime(
        tz.local,
        targetDay.year,
        targetDay.month,
        targetDay.day,
        9,
      );

      if (!scheduled.isAfter(now)) continue;

      final body = switch (daysBefore) {
        0 => '${food.name} expire aujourd\'hui.',
        1 => '${food.name} expire demain.',
        _ => '${food.name} expire dans $daysBefore jours.',
      };

      await _plugin.zonedSchedule(
        _notificationId(food.id, daysBefore),
        'Rappel DLC',
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Alertes avant la date limite de consommation',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelFoodReminders(String foodId) async {
    for (final daysBefore in _reminderOffsets) {
      await _plugin.cancel(_notificationId(foodId, daysBefore));
    }
  }

  Future<void> rescheduleAll(Iterable<Food> foods) async {
    for (final food in foods) {
      await syncFoodReminders(food);
    }
  }

  int _notificationId(String foodId, int daysBefore) {
    // Stable positive 31-bit id derived from food id + offset.
    final base = foodId.hashCode & 0x3fffffff;
    return base + daysBefore;
  }
}
