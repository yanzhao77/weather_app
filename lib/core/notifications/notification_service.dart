import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 本地每日天气提醒（基于 flutter_local_notifications 的 zonedSchedule）
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const int _dailyWeatherId = 1001;
  static const String _channelId = 'daily_weather';
  static const String _channelName = '每日天气提醒';

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (e) {
      // 通知插件初始化失败不应阻塞应用启动
      debugPrint('[NEXUS][notify] init failed: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (!_initialized) await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 调度每天本地时间 08:00 的天气提醒
  static Future<void> scheduleDailyWeatherReminder() async {
    if (!_initialized) await init();
    final now = DateTime.now();
    var scheduledLocal = DateTime(now.year, now.month, now.day, 8, 0);
    if (!scheduledLocal.isAfter(now)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }
    // 本地时间换算为绝对时刻（UTC 表示），避免 tz.local 时区偏差
    final scheduled = tz.TZDateTime.from(scheduledLocal.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      _dailyWeatherId,
      '今日天气提醒',
      '来看看今天的天气吧',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: '每日定时天气提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDailyWeatherReminder() async {
    await _plugin.cancel(_dailyWeatherId);
  }
}
